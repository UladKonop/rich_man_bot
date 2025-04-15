require 'rails_helper'

RSpec.describe Webhooks::PaymentsController, type: :controller do
  fixtures :all

  describe 'POST create' do
    let(:user) { users(:default) }
    let(:params) do
      { 
        'notification_type' => 'p2p-incoming',
        'bill_id' => '',
        'amount' => '791.77',
        'datetime' => '2020-09-02T14:24:30Z',
        'codepro' => 'false',
        'sender' => '41001000040',
        'sha1_hash' => '9703c86510f42d17d179c01cfe85740f291c7842',
        'test_notification' => 'false',
        'operation_label' => '',
        'operation_id' => 'test-notification',
        'currency' => '643',
        'label' => %Q[{"chat_id":"#{user.chat_id}","subscription_type":"month"}],
        'controller' => 'payments',
        'action' => 'create' 
      }
    end

    context 'success' do
      it 'creates' do
        post(:create, params: params)
        expect(response.status).to eq 200
      end
    end
  end
end
