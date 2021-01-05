#!/usr/bin/env ruby
require 'colored'
require 'open3'
require 'slack-notifier'
require 'socket'

class Sync
  def initialize(source, ssh_port, ssh_username, ssh_host, destination, logfile, slack_webhook)
    @source = source
    @ssh_username = ssh_username
    @ssh_port = ssh_port
    @ssh_host = ssh_host
    @destination = destination
    @logfile = logfile
    @slack_webhook = slack_webhook
  end

  def now(
    source = @source,
    ssh_port = @ssh_port,
    ssh_username = @ssh_username,
    ssh_host = @ssh_host,
    destination = @destination,
    logfile = @logfile,
    slack_webhook = @slack_webhook
  )

    hostname = Socket.gethostname

   destination_string = "#{ssh_username}" + "@" + "#{ssh_host}" + ":" + "#{destination}"

    if ssh_port
      ssh_string = "'ssh -p 22'"
      ssh_string.sub! '22', ssh_port
    else
      ssh_string = "'ssh -p 22'"
    end

    cmd = 'rsync -avz -e ' \
    + ssh_string + \
    ' --exclude=".DS_Store" ' \
    + source \
    + " " \
    + destination_string

    stdout, stderr, status = Open3.capture3(cmd)

    notifier = Slack::Notifier.new(slack_webhook)

    danger_note = {
      fallback: "Fallback text",
      text: "#{hostname} #{cmd}",
      color: "danger"
    }

    if status.success?
      puts 'Syncing...'.yellow
      puts stdout
      puts 'Syncing complete!'.green
    else
      notifier.post text: "error #{stderr.red} .",
      icon_emoji: ":bangbang:",
      color: "danger",
      username: "Server: #{hostname} backup to #{ssh_host}",
      attachments: [danger_note]
      abort "error: could not execute command #{cmd} ".red + stderr.red
    end
  end
end
