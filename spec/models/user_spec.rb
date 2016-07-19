require 'spec_helper'

RSpec.describe OpenVASClient::User, type: :model do
  before do
    @agent = OpenVASClient::OpenVASAgent.new()
  end

  describe 'create User' do
    it 'with valid arguments' do
      expect(OpenVASClient::User.new(Faker::Name.first_name, Faker::Internet.password, @agent).id).not_to eq(nil)
    end

    it 'with invalid arguments -> spaces in name' do
      expect{ OpenVASClient::User.new(Faker::Name.name, Faker::Internet.password, @agent) }.to raise_error(OpenVASClient::OpenVASError, 'Invalid characters in user name')
    end
  end
end
