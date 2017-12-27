require 'spec_helper'

module Bosh
  module Director
    describe VmDeleter do
      subject { VmDeleter.new(logger) }

      let(:cloud) { Config.cloud }
      let(:cloud_factory) { instance_double(CloudFactory) }
      let(:deployment) { Models::Deployment.make(name: 'deployment_name') }
      let(:vm_model) { Models::Vm.make(cid: 'vm-cid', instance_id: instance_model.id, cpi: 'cpi1') }
      let(:instance_model) { Models::Instance.make(uuid: SecureRandom.uuid, index: 5, job: 'fake-job', deployment: deployment, availability_zone: 'az1') }

      before do
        instance_model.active_vm = vm_model

        allow(CloudFactory).to receive(:create_with_latest_configs).and_return(cloud_factory)
        allow(cloud_factory).to receive(:get).with(nil).and_return(cloud)
      end

      describe '#delete_vm_by_cid' do
        it 'calls delete_vm if only one cloud is configured' do
          allow(cloud_factory).to receive(:uses_cpi_config?).and_return(false)

          expect(logger).to receive(:info).with('Deleting VM')
          expect(cloud).to receive(:delete_vm).with(vm_model.cid)
          subject.delete_vm_by_cid(vm_model.cid)
        end

        it 'does not call delete_vm if multiple clouds are configured' do
          allow(cloud_factory).to receive(:uses_cpi_config?).and_return(true)

          expect(logger).to receive(:info).with('Deleting VM')
          expect(cloud).to_not receive(:delete_vm).with(vm_model.cid)
          subject.delete_vm_by_cid(vm_model.cid)
        end

        context 'when virtual delete is enabled' do
          subject { VmDeleter.new(logger, false, true) }

          it 'skips calling delete_vm on the cloud' do
            allow(cloud_factory).to receive(:uses_cpi_config?).and_return(false)

            expect(logger).to receive(:info).with('Deleting VM')
            expect(cloud).not_to receive(:delete_vm)
            subject.delete_vm_by_cid(vm_model.cid)
          end
        end
      end
    end
  end
end
