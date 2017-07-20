module Emails
  module Members
    extend ActiveSupport::Concern
    include MembersHelper

    included do
      helper_method :member_source, :member
    end

    def member_access_requested_email(member_source_type, member_id)
      @member_source_type = member_source_type
      @member_id = member_id

      admins = member_source.members.owners_and_masters.pluck(:notification_email)
      # A project in a group can have no explicit owners/masters, in that case
      # we fallbacks to the group's owners/masters.
      if admins.empty? && member_source.respond_to?(:group) && member_source.group
        admins = member_source.group.members.owners_and_masters.pluck(:notification_email)
      end

      mail(to: admins,
           subject: subject("Request to join the #{member_source.human_name} #{member_source.model_name.singular}"))
    end

    def member_access_granted_email(member_source_type, member_id)
      @member_source_type = member_source_type
      @member_id = member_id

      mail(to: member.user.notification_email,
           subject: subject("Access to the #{member_source.human_name} #{member_source.model_name.singular} was granted"))
    end

    def member_access_denied_email(member_source_type, source_id, user_id)
      @member_source_type = member_source_type
      @member_source = member_source_class.find(source_id)
      access_request_user = User.find(user_id)

      mail(to: access_request_user.notification_email,
           subject: subject("Access to the #{member_source.human_name} #{member_source.model_name.singular} was denied"))
    end

    def member_invited_email(member_source_type, member_id, token)
      @member_source_type = member_source_type
      @member_id = member_id
      @token = token

      mail(to: member.invite_email,
           subject: subject("Invitation to join the #{member_source.human_name} #{member_source.model_name.singular}"))
    end

    def member_invite_accepted_email(member_source_type, member_id)
      @member_source_type = member_source_type
      @member_id = member_id
      return unless member.created_by

      mail(to: member.created_by.notification_email,
           subject: subject('Invitation accepted'))
    end

    def member_invite_declined_email(member_source_type, source_id, invite_email, created_by_id)
      return unless created_by_id

      @member_source_type = member_source_type
      @member_source = member_source_class.find(source_id)
      @invite_email = invite_email
      inviter = User.find(created_by_id)

      mail(to: inviter.notification_email,
           subject: subject('Invitation declined'))
    end

    def member
      @member ||= Member.find(@member_id)
    end

    def member_source
      @member_source ||= member.source
    end

    private

    def member_source_class
      @member_source_type.classify.constantize
    end
  end
end
