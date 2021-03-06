def main(argv)
  case argv[0]
  when 'db'
    foreman_exec(%w[redis postgresql openldap influxdb webpack registry minio elasticsearch])
  when 'geo_db'
    foreman_exec(%w[postgresql-geo])
  when 'app'
    svcs = %w[gitlab-workhorse nginx grafana sshd gitaly storage-check]

    if argv[1] == 'rails5'
      foreman_exec(svcs + %w[rails5-web rails5-background-jobs], exclude: %w[rails-web rails-background-jobs])
    else
      foreman_exec(svcs + %w[rails-web rails-background-jobs], exclude: %w[rails5-web rails5-background-jobs])
    end
  when 'grafana'
    foreman_exec(%w[grafana])
  when 'thin'
    exec(
      {'RAILS_ENV' => 'development'},
      *%W[bundle exec thin --socket=#{Dir.pwd}/gitlab.socket start],
      chdir: 'gitlab'
    )
  when 'gitaly'
    foreman_exec(%w[gitaly])
  when 'rails5'
    print_url
    foreman_exec(%w[all], exclude: %w[rails-web rails-background-jobs])
  else
    print_url
    foreman_exec(%w[all], exclude: %w[rails5-web rails5-background-jobs])
  end
end

def foreman_exec(svcs=[], exclude: [])
  args = %w[foreman start]
  unless svcs.empty? && exclude.empty?
    args << '-m'
    svc_string = ['all=0', svcs.map { |svc| svc + '=1' }, exclude.map { |svc| svc + '=0' }].join(',')
    args << svc_string
  end
  exec(*args)
end

def print_url
  printf "

           \033[38;5;88m\`                        \`
          :s:                      :s:
         \`oso\`                    \`oso.
         +sss+                    +sss+
        :sssss:                  -sssss:
       \`ossssso\`                \`ossssso\`
       +sssssss+                +sssssss+
      -ooooooooo-++++++++++++++-ooooooooo-
     \033[38;5;208m\`:/\033[38;5;202m+++++++++\033[38;5;88mosssssssssssso\033[38;5;202m+++++++++\033[38;5;208m/:\`
     -///\033[38;5;202m+++++++++\033[38;5;88mssssssssssss\033[38;5;202m+++++++++\033[38;5;208m///-
    .//////\033[38;5;202m+++++++\033[38;5;88mosssssssssso\033[38;5;202m+++++++\033[38;5;208m//////.
    :///////\033[38;5;202m+++++++\033[38;5;88mosssssssso\033[38;5;202m+++++++\033[38;5;208m///////:
     .:///////\033[38;5;202m++++++\033[38;5;88mssssssss\033[38;5;202m++++++\033[38;5;208m///////:.\`
       \`-://///\033[38;5;202m+++++\033[38;5;88mosssssso\033[38;5;202m+++++\033[38;5;208m/////:-\`
          \`-:////\033[38;5;202m++++\033[38;5;88mosssso\033[38;5;202m++++\033[38;5;208m////:-\`
             .-:///\033[38;5;202m++\033[38;5;88mosssso\033[38;5;202m++\033[38;5;208m///:-.
               \`.://\033[38;5;202m++\033[38;5;88mosso\033[38;5;202m++\033[38;5;208m//:.\`
                  \`-:/\033[38;5;202m+\033[38;5;88moo\033[38;5;202m+\033[38;5;208m/:-\`
                     \`-++-\`\033[0m

  "
  puts
  puts
  puts "Starting GitLab in #{Dir.pwd} on http://#{ENV['host']}:#{ENV['port']}#{ENV['relative_url_root']}"
  puts
  puts

end

main(ARGV)
