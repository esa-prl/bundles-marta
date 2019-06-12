#!/usr/bin/env ruby

require 'orocos'
require 'rock/bundle'
require 'readline'
include Orocos

# Initialize bundles to find the configurations for the packages
Bundles.initialize

Orocos::Process.run 'control', 'unit_vicon', 'navigation' do

    joystick = Orocos.name_service.get 'joystick'
    Orocos.conf.apply(joystick, ['default', 'logitech_gamepad'], :override => true)
    begin
        joystick.configure
    rescue
        abort("Cannot configure the joystick, is the dongle connected to MaRTA?")
    end

    motion_translator = Orocos.name_service.get 'motion_translator'
    Orocos.conf.apply(motion_translator, ['marta'], :override => true)
    motion_translator.configure

    locomotion_control = Orocos.name_service.get 'locomotion_control'
    Orocos.conf.apply(locomotion_control, ['marta'], :override => true)
    locomotion_control.configure

    wheel_walking_control = Orocos.name_service.get 'wheel_walking_control'
    Orocos.conf.apply(wheel_walking_control, ['marta'], :override => true)
    wheel_walking_control.configure

    locomotion_switcher = Orocos.name_service.get 'locomotion_switcher'
    Orocos.conf.apply(locomotion_switcher, ['default'], :override => true)
    locomotion_switcher.configure

    command_joint_dispatcher = Orocos.name_service.get 'command_joint_dispatcher'
    Orocos.conf.apply(command_joint_dispatcher, ['marta_commanding'], :override => true)
    command_joint_dispatcher.configure

    platform_driver = Orocos.name_service.get 'platform_driver_marta'
    Orocos.conf.apply(platform_driver, ['default'], :override => true)
    platform_driver.configure

    read_joint_dispatcher = Orocos.name_service.get 'read_joint_dispatcher'
    Orocos.conf.apply(read_joint_dispatcher, ['marta_reading'], :override => true)
    read_joint_dispatcher.configure

    ptu_control = Orocos.name_service.get 'ptu_control'
    Orocos.conf.apply(ptu_control, ['default'], :override => true)
    ptu_control.configure

    vicon = Orocos.name_service.get 'vicon'
    Orocos.conf.apply(vicon, ['default', 'marta'], :override => true)
    vicon.configure

    waypoint_navigation = Orocos.name_service.get 'waypoint_navigation'
    Orocos.conf.apply(waypoint_navigation, ['marta'], :override => true)
    waypoint_navigation.configure

    trajectory_generator = Orocos.name_service.get 'trajectoryGen'
    Orocos.conf.apply(trajectory_generator, ['astra_2019_demo'], :override => true)
    trajectory_generator.configure

    command_arbiter = Orocos.name_service.get 'command_arbiter'
    Orocos.conf.apply(command_arbiter, ['default'], :override => true)
    command_arbiter.configure

    # Log
    #Orocos.log_all_ports
    #platform_driver.log_all_ports
    #pancam_panorama.log_all_ports

    # Connect
    joystick.raw_command.connect_to                     motion_translator.raw_command
    joystick.raw_command.connect_to                     command_arbiter.raw_command

    motion_translator.motion_command.connect_to         command_arbiter.joystick_motion_command
    waypoint_navigation.motion_command.connect_to       command_arbiter.follower_motion_command
    command_arbiter.motion_command.connect_to           locomotion_switcher.motion_command
    command_arbiter.locomotion_mode.connect_to          locomotion_switcher.locomotion_mode_override

    motion_translator.ptu_command.connect_to            ptu_control.ptu_joints_commands
    ptu_control.ptu_commands_out.connect_to             command_joint_dispatcher.ptu_commands

    locomotion_switcher.kill_switch.connect_to          wheel_walking_control.kill_switch
    locomotion_switcher.reset_dep_joints.connect_to     wheel_walking_control.reset_dep_joints
    locomotion_switcher.lc_motion_command.connect_to    locomotion_control.motion_command
    read_joint_dispatcher.joints_samples.connect_to     locomotion_switcher.joints_readings
    read_joint_dispatcher.motors_samples.connect_to     locomotion_switcher.motors_readings

    locomotion_control.joints_commands.connect_to       locomotion_switcher.lc_joints_commands
    wheel_walking_control.joint_commands.connect_to     locomotion_switcher.ww_joints_commands

    locomotion_switcher.joints_commands.connect_to      command_joint_dispatcher.joints_commands

    command_joint_dispatcher.motors_commands.connect_to platform_driver.joints_commands
    platform_driver.joints_readings.connect_to          read_joint_dispatcher.joints_readings
    read_joint_dispatcher.motors_samples.connect_to     locomotion_control.joints_readings
    read_joint_dispatcher.joints_samples.connect_to     wheel_walking_control.joint_readings
    read_joint_dispatcher.ptu_samples.connect_to        ptu_control.ptu_samples

    ptu_control.ptu_commands_out.connect_to             command_joint_dispatcher.ptu_commands

    trajectory_generator.trajectory.connect_to          waypoint_navigation.trajectory
    vicon.pose_samples.connect_to                       waypoint_navigation.pose

    # Start
    platform_driver.start
    read_joint_dispatcher.start
    command_joint_dispatcher.start
    locomotion_control.start
    wheel_walking_control.start
    locomotion_switcher.start
    ptu_control.start
    motion_translator.start
    joystick.start
    command_arbiter.start

    vicon.start
    waypoint_navigation.start

    Readline::readline("Press Enter to start following trajectory\n") do
    end

    trajectory_generator.start

    Readline::readline("Press Enter to exit\n") do
    end
end
