# -*- coding: utf-8 -*-
require 'ostruct'
require 'pathname'
require 'ekylibre'

# Build a task with a transaction
def load_data(name, &block)
  task(name => :environment) do
    folder = ENV["folder"]
    folder = "default" if Ekylibre::FirstRun.path.join("default").exist?
    folder ||= "demo"
    ActiveRecord::Base.transaction do
      yield Ekylibre::FirstRun::Loader.new(folder)
    end
  end
end

namespace :first_run do
  for loader in Ekylibre::FirstRun::LOADERS
    require Pathname.new(__FILE__).dirname.join("first_run", loader.to_s).to_s
  end
end

desc "Create first_run data -- also available " + Ekylibre::FirstRun::LOADERS.collect{|c| "first_run:#{c}"}.join(", ")
task :first_run => :environment do
  ActiveRecord::Base.transaction do
    for loader in Ekylibre::FirstRun::LOADERS
      Rake::Task["first_run:#{loader}"].invoke
    end
  end
end

namespace :first_runs do

  Ekylibre::FirstRun::LOADERS.each_with_index do |loader, index|
    loaders = Ekylibre::FirstRun::LOADERS[index..-1]
    code  = "desc 'Execute #{loaders.to_sentence}'\n"
    code << "task :#{loader} do\n"
    for d in loaders
      code << "  puts 'Load #{d.to_s.red}:'\n"
      code << "  Rake::Task['first_run:#{d}'].invoke\n"
    end
    code << "end"
    eval code
  end

end


desc "Create first_run data independently -- also available " + Ekylibre::FirstRun::LOADERS.collect{|c| "first_run:#{c}"}.join(", ")
task :first_runs => :environment do
  for loader in Ekylibre::FirstRun::LOADERS
    puts "Load #{loader.to_s.red}:"
    Rake::Task["first_run:#{loader}"].invoke
  end
end


