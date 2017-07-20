require 'spec_helper'

describe AccessRequestsFinder do
  let(:user) { create(:user) }
  let(:access_request_user) { create(:user) }

  let(:project) do
    create(:project, :public, :access_requestable) do |project|
      project.request_access(access_request_user)
    end
  end

  let(:group) do
    create(:group, :public, :access_requestable) do |group|
      group.request_access(access_request_user)
    end
  end

  shared_examples 'a finder returning access requests' do |method_name|
    it 'returns access requests' do
      access_requests = described_class.new(source).public_send(method_name, user)

      expect(access_requests.size).to eq(1)
      expect(access_requests.first).to be_a "#{source.class}Member".constantize
      expect(access_requests.first.user).to eq(access_request_user)
    end
  end

  shared_examples 'a finder returning no results' do |method_name|
    it 'raises Gitlab::Access::AccessDeniedError' do
      expect(described_class.new(source).public_send(method_name, user)).to be_empty
    end
  end

  shared_examples 'a finder raising Gitlab::Access::AccessDeniedError' do |method_name|
    it 'raises Gitlab::Access::AccessDeniedError' do
      expect { described_class.new(source).public_send(method_name, user) }.to raise_error(Gitlab::Access::AccessDeniedError)
    end
  end

  describe '#execute' do
    context 'when current user cannot see project access requests' do
      it_behaves_like 'a finder returning no results', :execute do
        let(:source) { project }
      end

      it_behaves_like 'a finder returning no results', :execute do
        let(:source) { group }
      end
    end

    context 'when current user can see access requests' do
      before do
        project.team << [user, :master]
        group.add_owner(user)
      end

      it_behaves_like 'a finder returning access requests', :execute do
        let(:source) { project }
      end

      it_behaves_like 'a finder returning access requests', :execute do
        let(:source) { group }
      end
    end
  end

  describe '#execute!' do
    context 'when current user cannot see access requests' do
      it_behaves_like 'a finder raising Gitlab::Access::AccessDeniedError', :execute! do
        let(:source) { project }
      end

      it_behaves_like 'a finder raising Gitlab::Access::AccessDeniedError', :execute! do
        let(:source) { group }
      end
    end

    context 'when current user can see access requests' do
      before do
        project.team << [user, :master]
        group.add_owner(user)
      end

      it_behaves_like 'a finder returning access requests', :execute! do
        let(:source) { project }
      end

      it_behaves_like 'a finder returning access requests', :execute! do
        let(:source) { group }
      end
    end
  end
end
