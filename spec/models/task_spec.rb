require 'spec_helper'

RSpec.describe OpenVASClient::Task, type: :model do
  before do
    @agent = OpenVASClient::OpenVASAgent.new()
  end

  describe 'create Task' do
    it 'with valid arguments' do
      target = OpenVASClient::Target.new(Faker::Lorem.word, 'localhost', @agent)
      expect(OpenVASClient::Task.new(Faker::Lorem.word, target, @agent).id).not_to eq(nil)
    end
  end

  describe 'destroy Task' do
    it 'with valid arguments' do
      target = OpenVASClient::Target.new(Faker::Lorem.word, 'localhost', @agent)
      task = OpenVASClient::Task.new(Faker::Lorem.word, target, @agent)
      expect(task.destroy).to eq(true)
    end
  end

  describe 'running Task' do
    it 'with valid arguments' do
      target = OpenVASClient::Target.new(Faker::Lorem.word, 'localhost', @agent)
      task = OpenVASClient::Task.new(Faker::Lorem.word, target, @agent)
      expect(task.start).to eq(true)
      expect(task.stop).to eq(true)
      sleep(10) # Necessary to resume current task
      expect(task.resume).to eq(nil)
      task.stop
    end

    it 'with invalid arguments -> resume too fast' do
      target = OpenVASClient::Target.new(Faker::Lorem.word, 'localhost', @agent)
      task = OpenVASClient::Task.new(Faker::Lorem.word, target, @agent)
      expect(task.start).to eq(true)
      expect(task.stop).to eq(true)
      expect{ task.resume }.to raise_error(OpenVASClient::OpenVASError, 'Task must be in Stopped state')
    end
  end
end
