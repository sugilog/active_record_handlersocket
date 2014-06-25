namespace :travis do
  desc "build HandlerSocket-Plugin-for-Mysql for Travis CI"
  task :build do
    if handlersocket_plugin_installed?
      STDOUT.puts "HandlerSocket-Plugin-for-MySQL already installed"
    else
      %W[
        clone_handler_socket
        prepare_mysql_source
        make_handler_socket
        update_mysql_config
        add_handlersocket_for_mysql
        install_handlersocket_gem
      ].each do |task|
        Rake::Task["travis:" + task].invoke
      end
    end
  end

  task :clone_handler_socket do
    execute "git clone https://github.com/DeNA/HandlerSocket-Plugin-for-MySQL.git"
  end

  task :prepare_mysql_source do
    execute "cd #{handlersocket_plugin_dir}; wget #{mysql_download_url}"
    # if on debug, add v option for tar command.
    execute "cd #{handlersocket_plugin_dir}; tar xf #{mysql_filename}"
  end

  task :make_handler_socket do
    execute "cd #{handlersocket_plugin_dir}; ./autogen.sh"
    execute "cd #{handlersocket_plugin_dir}; ./configure --with-mysql-source=#{mysql_source} --with-mysql-bindir=#{mysql_bin} --prefix=#{configure_prefix}"
    execute "cd #{handlersocket_plugin_dir}; make"
    execute "cd #{handlersocket_plugin_dir}; sudo make install"
  end

  task :update_mysql_config do
    original_config = `sudo cat /etc/my.cnf`

    File.open "my.cnf", "w" do |f|
      f.puts original_config
      f.puts handlersocket_config
    end

    execute "sudo mv -f my.cnf /etc/my.cnf"
  end

  task :add_handlersocket_for_mysql do
    execute %Q|mysql -u root -e "install plugin handlersocket soname 'handlersocket.so'"|
    execute %Q|mysql -u root -e "SHOW PLUGINS"|
  end

  task :install_handlersocket_gem do
    execute "gem install handlersocket -- --with-opt-include=#{configure_prefix}/include/handlersocket"
  end

  def execute(command)
    STDOUT.puts ""
    command = command + " 2>&1"
    STDOUT.puts [ "**", "Exec:", command ].join(" ")
    result = system command
    STDOUT.puts [ "**", "Result:", result ].join(" ")
  end

  def handlersocket_plugin_installed?
    `mysql -e "SHOW PLUGINS" | grep handlersocket | wc -l`.chomp.to_i > 0
  end

  def configure_prefix
    "/usr/local"
  end

  def base_dir
    dir = File.dirname __FILE__
    File.expand_path dir
  end

  def handlersocket_plugin_dir
    "HandlerSocket-Plugin-for-MySQL"
  end

  def mysql_source
    dirname = File.basename mysql_filename, ".tar.gz"
    File.join base_dir, handlersocket_plugin_dir, dirname
  end

  def mysql_download_url
    "http://downloads.mysql.com/archives/mysql-#{mysql_version.split(".")[0..1].join(".")}/#{mysql_filename}"
  end

  def mysql_filename
    "mysql-#{mysql_version}.tar.gz"
  end

  def mysql_version
    `mysql_config --version`.chomp
  end

  def mysql_bin
    File.dirname `which mysql`.chomp
  end

  def handlersocket_config
    <<-EOC
  [mysqld]
  handlersocket_port    = 9998
  handlersocket_port_wr = 9999
  handlersocket_address =
  handlersocket_verbose = 0
  handlersocket_timeout = 300
  handlersocket_threads = 16
  thread_concurrency    = 128
  open_files_limit      = 65535
    EOC
  end
end
