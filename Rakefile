# rubocop: disable all
#  reason: apparently rubocop and rake don't play nice together.
#

require 'bundler/setup'

### Local custom requires
require 'cts/mpx/aci/version'

### Configurables
version = Cts::Mpx::Aci::VERSION
name = "cts-mpx-aci"
geminabox_server = "http://ctsgems.corp.theplatform.com"

### Basic Tasks
task default: :rspec
desc "run the rspec suite"

task "rspec" do
  sh 'rspec'
end

desc "bundle"
task :bundle do
  sh "bundle"
end

namespace :gem do
  desc "build #{name}-#{version} of the gem in pkg/"
  task build: [:bundle] do
    sh "gem build #{name}.gemspec"
    mkdir_p "pkg"
    mv "#{name}-#{version}.gem", "pkg"
  end

  desc "install pkg/#{name}-#{version}.gem into the system"
  task install: [:build] do
    sh "gem install pkg/#{name}-#{version}.gem"
  end

  desc "Run rubocop"
  task rubocop: [] do
    sh "rubocop -fh --out rubocop.html"
    sh "rubocop -fs"
  end

  namespace :release do
    desc "tag current version as #{version}"
    task :tag do
      begin
        sh "git tag v#{version}"
      rescue StandardError
      end
    end

    desc "push gem #{name}-#{version} to #{geminabox_server}"
    task gem: ['gem:build'] do
      sh "gem inabox -g #{geminabox_server}"
    end
  end

  desc "tag #{name}-#{version} and release push #{name}-#{version}"
  task release: ['release:gem', 'release:tag']
end

namespace 'gh-pages' do
  desc "initialize gh-pages directory and remote repo"
  task "initialize": ['bundle'] do
    rm_rf 'gh-pages' if File.exist? 'gh-pages'
    sh "git clone . gh-pages"
    cd "gh-pages"
    sh "git checkout --orphan gh-pages"
    sh "git rm -rf ."
    sh "git remote rm origin"
    sh "git remote add origin git@github.comcast.com:cts-unified-ingest/cts-mpx-aci.git"
    cd ".."
  end

  desc "build specifications html file for documentation"
  task "specifications" do
    mkdir_p 'tmp'
    sh "rspec -fh > tmp/specifications.html"
  end

  desc "build reference docs via yardoc"
  task "reference-docs" do
    sh "yardoc"
  end

  desc "build github pages"
  task "build": ['initialize', 'reference-docs', 'specifications'] do
    sh 'nanoc'
  end

  desc "push gh-pages to github.comcast.com"
  task "release": ['build'] do
    cd "gh-pages"
    sh "git add ."
    sh "git commit -m \'Updated at: #{Time.now} for version: #{version}\'"
    sh "git push origin gh-pages -f"
    cd ".."
  end
end

# rubocop: enable all
