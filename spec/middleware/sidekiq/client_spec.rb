# frozen_string_literal: true

require 'pg_rls/middleware/sidekiq/client'
require 'sidekiq/testing'

# Define the dummy workers
class DummyAdminWorker
  include Sidekiq::Worker

  def perform(*_args)
    raise 'Not an admin connection' unless PgRls.admin_connection?

    'Admin task'
  end
end

class DummyTenantWorker
  include Sidekiq::Worker

  def perform(*_args)
    raise 'Not a tenant connection' if PgRls.admin_connection?

    PgRls::Tenant.fetch
  end
end

class DummyFailingWorker
  include Sidekiq::Worker

  def perform(*_args)
    raise 'Failed job'
  end
end

RSpec.describe PgRls::Middleware::Sidekiq::Client do
  before(:all) do
    Sidekiq.configure_client do |config|
      config.logger.level = Logger::WARN
      config.client_middleware do |chain|
        chain.add described_class
      end
    end
  end

  describe 'middleware behavior' do
    context 'when admin connection is true' do
      before do
        allow(PgRls).to receive(:admin_connection?).and_return(true)
      end

      it 'sets admin attribute to true for the job' do
        Sidekiq::Testing.inline! do
          DummyAdminWorker.perform_async
        end
      end
    end

    context 'when admin connection is false' do
      let(:tenant) { double('Tenant', id: 123) }

      before do
        allow(PgRls).to receive(:admin_connection?).and_return(false)
        allow(PgRls::Tenant).to receive(:fetch).and_return(tenant)
      end

      it 'sets pg_rls attribute with tenant id for the job' do
        Sidekiq::Testing.inline! do
          DummyTenantWorker.perform_async
        end
      end
    end

    context 'when the job fails' do
      let(:tenant) { double('Tenant', id: 123) }

      before do
        allow(PgRls).to receive(:admin_connection?).and_return(false)
        allow(PgRls::Tenant).to receive(:fetch).and_return(tenant)
      end

      it 'raises the error triggered by the job (not other raised in the middleware)' do
        Sidekiq::Testing.inline! do
          expect { DummyFailingWorker.perform_async }.to raise_error('Failed job')
        end
      end
    end
  end
end
