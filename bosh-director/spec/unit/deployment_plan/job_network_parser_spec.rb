require 'spec_helper'

module Bosh::Director::DeploymentPlan
  describe JobNetworksParser do
    let(:job_networks_parser) { JobNetworksParser.new(Network::VALID_DEFAULTS) }
    let(:job_spec) do
      job = Bosh::Spec::Deployments.simple_manifest['jobs'].first
      job_network = job['networks'].first
      job_network['static_ips'] = ['192.168.1.1']
      job
    end
    let(:manifest_networks) { [ManualNetwork.new('a', [], logger)] }

    context 'when job references a network not mentioned in the networks spec' do
      let(:manifest_networks) { [ManualNetwork.new('my-network', [], logger)] }

      it 'raises JobUnknownNetwork' do
        expect {
          job_networks_parser.parse(job_spec, 'job-name', manifest_networks)
        }.to raise_error BD::JobUnknownNetwork, "Job 'job-name' references an unknown network 'a'"
      end
    end

    context 'when job spec is missing network information' do
      let(:job_spec) do
        job = Bosh::Spec::Deployments.simple_manifest['jobs'].first
        job['networks'] = []
        job
      end

      it 'raises JobMissingNetwork' do
        expect {
          job_networks_parser.parse(job_spec, 'job-name', manifest_networks)
        }.to raise_error BD::JobMissingNetwork, "Job `job-name' must specify at least one network"
      end
    end

    context 'when called with a valid job spec' do
      it 'adds static ips to job networks' do
        networks = job_networks_parser.parse(job_spec, 'job-name', manifest_networks)

        expect(networks.count).to eq(1)
        expect(networks.first).to be_a_job_network(
            JobNetwork.new('a', ['192.168.1.1'], ['dns', 'gateway'], manifest_networks.first)
          )
      end
    end

    RSpec::Matchers.define :be_a_job_network do |expected|
      match do |actual|
        actual.name == expected.name &&
          actual.static_ips == expected.static_ips.map { |ip_to_i| NetAddr::CIDR.create(ip_to_i) } &&
          actual.deployment_network == expected.deployment_network
      end
    end
  end
end
