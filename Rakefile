require 'rake/testtask'

task :default => 'specs'

Rake::TestTask.new('specs') do |t|
  t.libs << %w(spec lib)
  t.pattern = 'spec/**/*_spec.rb'
end
