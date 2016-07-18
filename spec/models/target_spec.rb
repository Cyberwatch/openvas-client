require 'spec_helper'

RSpec.describe OpenVASClient::Target, type: :model do
  before do
    @agent = OpenVASClient::OpenVASAgent.new()
  end

  describe 'create Target' do
    it 'with valid arguments' do
      expect(OpenVASClient::Target.new(Faker::Company.name, 'localhost', @agent).id).not_to eq(nil)
    end

    it 'with invalid arguments -> name already exists' do
      name = Faker::Company.name
      OpenVASClient::Target.new(name, 'localhost', @agent)
      expect{ OpenVASClient::Target.new(name, 'localhost', @agent) }.to raise_error(OpenVASClient::OpenVASError, 'Target exists already')
    end
  end
end
