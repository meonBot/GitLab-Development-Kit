# GitLab Development Kit CLI parser / executor
#
# This file is loaded by the 'gdk' command in the gem. This file is NOT
# part of the gitlab-development-kit gem so that we can iterate faster.

module GDK
  PROGNAME = 'gdk'.freeze
  MAKE = RUBY_PLATFORM =~ /bsd/ ? 'gmake' : 'make'

  # This function is called from bin/gdk. It must return true/false or
  # an exit code.
  def self.main
    if !install_root_ok? && ARGV.first != 'reconfigure'
      puts <<-EOS.gsub(/^\s+\|/, '')
        |According to #{ROOT_CHECK_FILE} this gitlab-development-kit
        |installation was moved. Run 'gdk reconfigure' to update hard-coded
        |paths.
      EOS
      return false
    end

    pg_port_file = File.join($gdk_root, 'postgresql_port')
    pg_port = File.exist?(pg_port_file) ? File.read(pg_port_file) : 5432

    case ARGV.shift
    when 'run'
      exec('./run', *ARGV, chdir: $gdk_root)
    when 'install'
      exec(MAKE, *ARGV, chdir: $gdk_root)
    when 'update'
      # Otherwise we would miss it and end up in a weird state.
      puts "\n> Running `make self-update` separately in case the Makefile is updated..\n\n"
      system(MAKE, 'self-update', chdir: $gdk_root)

      puts "\n> Running `make self-update update`..\n\n"
      exec(MAKE, 'self-update', 'update', chdir: $gdk_root)
    when 'diff-config'
      require_relative './config_diff.rb'

      files = %w[
        gitlab/config/gitlab.yml
        gitlab/config/database.yml
        gitlab/config/unicorn.rb
        gitlab/config/resque.yml
        gitlab-shell/config.yml
        gitlab-shell/.gitlab_shell_secret
        redis/redis.conf
        .ruby-version
        Procfile
        gitlab-workhorse/config.toml
        gitaly/config.toml
        nginx/conf/nginx.conf
      ]

      file_diffs = files.map do |file|
        ConfigDiff.new(file)
      end

      file_diffs.each do |diff|
        $stderr.puts diff.make_output
      end

      file_diffs.each do |diff|
        puts diff.output unless diff.output == ""
      end

      true
    when 'reconfigure'
      remember!($gdk_root)
      exec(MAKE, 'clean-config', 'unlock-dependency-installers', 'postgresql-sensible-defaults', 'all', chdir: $gdk_root)
    when 'psql'
      exec('psql', '-h', File.join($gdk_root, 'postgresql'), '-p', pg_port.to_s, *ARGV, chdir: $gdk_root)
    when 'redis-cli'
      exec('redis-cli', '-s', File.join($gdk_root, 'redis/redis.socket'), *ARGV, chdir: $gdk_root)
    when 'help'
      puts File.read(File.join($gdk_root, 'HELP'))
      true
    else
      puts "Usage: #{PROGNAME} run|init|install|update|reconfigure|psql|redis-cli|diff-config|version|help [ARGS...]"
      false
    end
  end

  def self.install_root_ok?
    expected_root = File.read(File.join($gdk_root, ROOT_CHECK_FILE)).chomp
    File.realpath(expected_root) == File.realpath($gdk_root)
  rescue => ex
    warn ex
    false
  end
end
