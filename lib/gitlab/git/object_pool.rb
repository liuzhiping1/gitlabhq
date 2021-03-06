# frozen_string_literal: true

module Gitlab
  module Git
    class ObjectPool
      # GL_REPOSITORY has to be passed for Gitlab::Git::Repositories, but not
      # used for ObjectPools.
      GL_REPOSITORY = ""

      delegate :exists?, :size, to: :repository
      delegate :delete, to: :object_pool_service

      attr_reader :storage, :relative_path, :source_repository

      def initialize(storage, relative_path, source_repository)
        @storage = storage
        @relative_path = relative_path
        @source_repository = source_repository
      end

      def create
        object_pool_service.create(source_repository)
      end

      def link(to_link_repo)
        remote_name = to_link_repo.object_pool_remote_name
        repository.set_config(
          "remote.#{remote_name}.url" => relative_path_to(to_link_repo.relative_path),
          "remote.#{remote_name}.tagOpt" => "--no-tags",
          "remote.#{remote_name}.fetch" => "+refs/*:refs/remotes/#{remote_name}/*"
        )

        object_pool_service.link_repository(to_link_repo)
      end

      def gitaly_object_pool
        Gitaly::ObjectPool.new(repository: to_gitaly_repository)
      end

      def to_gitaly_repository
        Gitlab::GitalyClient::Util.repository(storage, relative_path, GL_REPOSITORY)
      end

      # Allows for reusing other RPCs by 'tricking' Gitaly to think its a repository
      def repository
        @repository ||= Gitlab::Git::Repository.new(storage, relative_path, GL_REPOSITORY)
      end

      private

      def object_pool_service
        @object_pool_service ||= Gitlab::GitalyClient::ObjectPoolService.new(self)
      end

      def relative_path_to(pool_member_path)
        pool_path = Pathname.new("#{relative_path}#{File::SEPARATOR}")

        Pathname.new(pool_member_path).relative_path_from(pool_path).to_s
      end
    end
  end
end
