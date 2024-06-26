# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Partitions::SetupDefaultService, feature_category: :ci_scaling do
  let(:service) { described_class.new }

  describe '.execute' do
    subject(:execute) { service.execute }

    context 'when ci_partitioning_first_records is disabled' do
      before do
        stub_feature_flags(ci_partitioning_first_records: false)
      end

      it 'does not create the default ci_partitions' do
        expect { execute }.not_to change { Ci::Partition }
      end
    end

    context 'when default ci_partitions do not exist' do
      it 'creates the default partitions', :aggregate_failures do
        expect { execute }.to change { Ci::Partition.count }.by(3)
      end
    end

    context 'when default partitions exist with incorrect statuses' do
      let(:status_active) { Ci::Partition.statuses[:active] }
      let(:status_current) { Ci::Partition.statuses[:current] }

      before do
        create_list(:ci_partition, 3)
      end

      it 'returns success and update statuses for ci_partitions', :aggregate_failures do
        expect { execute }.not_to change { Ci::Partition.count }
        expect(Ci::Partition.take(2).pluck(:status)).to contain_exactly(status_active, status_active)
        expect(Ci::Partition.last.status).to eq(status_current)
      end
    end
  end
end
