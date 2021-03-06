# encoding: utf-8
require 'spec_helper.rb'
require 'digest'
require 'yaml'

describe 'create bosh release task' do
  context 'when modifying release blobs' do
    let(:task_file) { 'spec/scripts/release/cf/upload_blobs/upload_blobs.yml' }

    before(:each) do
      File.open(task_file, 'w') do |f|
        f.puts <<HERE
platform: linux
image_resource:
  type: docker-image
  source:
    repository: cfbuildpacks/ci
inputs:
  - name: buildpacks-ci
  - name: cf-release
  - name: buildpack-releases
  - name: #{language}-buildpack-github-release
params:
  ACCESS_KEY_ID:
  SECRET_ACCESS_KEY:
  BUILDPACK_NAME:
run:
  path: buildpacks-ci/scripts/release/cf/upload_blobs
HERE
      end

      execute("-c #{task_file} " \
              '-i buildpacks-ci=. ' \
              '-i cf-release=./spec/scripts/release/cf/upload_blobs/cf-release ' \
              '-i buildpack-releases=. ' \
              "-i #{language}-buildpack-github-release=./spec/scripts/release/cf/upload_blobs/#{language}-buildpack-github-release")
    end

    let(:dirs) { run('ls /tmp/build/*/cf-release/blobs').lines.map { |dir| File.basename dir.strip } }

    context 'for java-offline buildpack' do
      let(:language) { 'java-offline' }

      it 'removes the corresponding key from the blobs.yml' do
        blobs = run('cat /tmp/build/*/cf-release/config/blobs.yml')
        parsed_blobs = YAML.load blobs
        key = parsed_blobs.find { |k, _| k == 'java-buildpack/java-buildpack-offline-v3.6.zip' }
        expect(parsed_blobs.keys.count).to eq(2)
        expect(key).to be_nil
      end

      it 'adds the new blob to the right directory' do
        expect(dirs).to eq(['java-buildpack'])
      end
    end

    context 'for java buildpack' do
      let(:language) { 'java' }

      it 'removes the corresponding key from the blobs.yml' do
        blobs = run('cat /tmp/build/*/cf-release/config/blobs.yml')
        parsed_blobs = YAML.load blobs
        key = parsed_blobs.find { |k, _| k == 'java-buildpack/java-buildpack-v3.6.zip' }
        expect(parsed_blobs.keys.count).to eq(2)
        expect(key).to be_nil
      end

      it 'adds the new blob to the right directory' do
        expect(dirs).to eq(['java-buildpack'])
      end
    end

    context 'for go buildpack' do
      let(:language) { 'go' }

      it 'removes the corresponding key from the blobs.yml' do
        blobs = run('cat /tmp/build/*/cf-release/config/blobs.yml')
        parsed_blobs = YAML.load blobs
        key = parsed_blobs.find { |k, _| k == 'go-buildpack/go_buildpack-cached-v1.7.2.zip' }
        expect(parsed_blobs.keys.count).to eq(2)
        expect(key).to be_nil
      end

      it 'adds the new blob to the right directory' do
        expect(dirs).to eq(['go-buildpack'])
      end
    end
  end
end
