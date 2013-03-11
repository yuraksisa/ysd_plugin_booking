require 'ysd_md_booking'
require 'ysd_plugin_booking'
require 'sinatra/base'
require 'sinatra/r18n'

class TestingSinatraApp < Sinatra::Base
  register Sinatra::R18n
  #
  # To throw exception in development MODE
  #
  set :raise_errors, true
  set :dump_errors, false
  set :show_exceptions, false
end

module DataMapper
  class Transaction
  	module SqliteAdapter
      def supports_savepoints?
        true
      end
  	end
  end
end

DataMapper::Logger.new(STDOUT, :debug)
DataMapper.setup :default, "sqlite3::memory:"
DataMapper::Model.raise_on_save_failure = true
DataMapper.finalize 

DataMapper.auto_migrate!