require 'spec_helper'

RSpec.describe OpenVASClient::Target, type: :model do
  before do
    @agent = OpenVASClient::OpenVASAgent.new()
  end

  describe 'create Target' do
    it 'with valid arguments' do
      expect(OpenVASClient::Target.new(Faker::Lorem.word, 'localhost', @agent).id).not_to eq(nil)
    end
  end
end
