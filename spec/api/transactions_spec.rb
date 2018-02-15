require 'spec_helper'
require 'pp'

describe 'transactions' do
  let(:access_token) { '9f1a2c4842b614a771aaae9220fc54ae835e298c4654dc2c9205fc1d7bd1a045' }
  let(:budget_id) { 'f419ac25-6217-4175-88dc-c3136ff5f6fd' }
  let(:client) { YnabApi::Client.new(access_token, 'api.localhost:3000', false) }
  let (:instance) { client.transactions }

  describe 'test an instance of TransactionsApi' do
    it 'should create an instance of TransactionApi' do
      expect(instance).to be_instance_of(YnabApi::TransactionsApi)
    end
  end

  describe 'authorization' do
    it "sets the Bearer Auth header correctly" do
      VCR.use_cassette("transactions") do
        response = instance.get_transactions(budget_id)
        expect(client.last_request.options[:headers]["Authorization"]).to eq "Bearer #{access_token}"

      end
    end

    it "throws when unauthorized" do
      VCR.use_cassette("transactions_unauthorized") do
        client = YnabApi::Client.new('not_valid_access_token', 'api.localhost:3000', false)
        begin
          response = client.transactions.get_transactions(budget_id)
        rescue YnabApi::ApiError => e
          expect(e.code).to be 401
          expect(client.last_request.response.options[:code]).to be 401
        end
      end
    end
  end

  describe 'GET /budgets/{budget_id}/transactions' do
    it "returns a list of transactions" do
      VCR.use_cassette("transactions") do
        response = instance.get_transactions(budget_id)
        expect(client.last_request.response.options[:code]).to be 200
        expect(response.data.transactions.length).to be 2
      end
    end
  end

  describe 'GET /budgets/{budget_id}/transaction/{payee_id}' do
    it "returns a payee" do
      VCR.use_cassette("transaction") do
        response = instance.get_transactions_by_id(budget_id, '81c374ff-74ab-4d6d-8d5a-ba3ad3fa68e4')
        expect(response.data.transaction).to be
        expect(response.data.transaction.amount).to eq -2000
      end
    end
  end

  describe 'POST /budgets/{budget_id}/transactions' do
    it "creates a transaction" do
      VCR.use_cassette("create_transaction") do
        response = instance.create_transaction(budget_id, {
          transaction: {
            date: '2018-01-01',
            account_id: '5982e895-98e5-41ca-9681-0b6de1036a1c',
            amount: 20000
          }
        })
        expect(client.last_request.response.options[:code]).to be 201
        expect(response.data.transaction).to be
        expect(response.data.transaction.amount).to eq 20000
      end
    end
  end

  describe 'PUT /budgets/{budget_id}/transactions/{transaction_id}' do
    it "updates a transaction" do
      VCR.use_cassette("update_transaction") do
        response = instance.update_transaction(budget_id, '4cd63d34-3814-4f50-abd0-59ce05b40d91', {
          transaction: {
            date: '2018-01-02',
            account_id: '5982e895-98e5-41ca-9681-0b6de1036a1c',
            amount: 30000
          }
        })
        expect(client.last_request.response.options[:code]).to be 200
        expect(response.data.transaction).to be
        expect(response.data.transaction.amount).to eq 30000
      end
    end
  end

  describe 'POST /budgets/{budget_id}/transactions/bulk' do
    it "bulk creations transactions" do
      VCR.use_cassette("bulk_transactions") do
        response = instance.bulk_create_transactions(budget_id, {
          transactions: [
            {
              date: '2018-01-01',
              account_id: '5982e895-98e5-41ca-9681-0b6de1036a1c',
              amount: 10000
            },
            {
              date: '2018-01-02',
              account_id: '5982e895-98e5-41ca-9681-0b6de1036a1c',
              amount: 20000
            },
            {
              date: '2018-01-03',
              account_id: '5982e895-98e5-41ca-9681-0b6de1036a1c',
              amount: 30000,
              import_id: '123456'
            }
          ]
        })
        expect(client.last_request.response.options[:code]).to be 201
        expect(response.data.bulk).to be
        expect(response.data.bulk.transaction_ids.length).to eq 3
        expect(response.data.bulk.duplicate_import_ids.length).to eq 0
      end
    end
  end
end
