# frozen_string_literal: true

# Mailer methods for all emails
class UserMailer < ActionMailer::Base
  prepend_view_path 'app/views/branded/'

  include MailerHelper
  helper MailerHelper
  helper FeedbacksHelper

  default from: Rails.configuration.x.organisation.email

  def welcome_notification(user)
    @user           = user
    @username       = @user.name
    # Override the default Rails route helper for the contact_us page IF an alternate contact_us
    # url was defined in the dmproadmap.rb initializer file
    @contact_us     = Rails.application.config.x.organisation.contact_us_url || contact_us_url

    mail(to: @user.email,
         subject: "Welcome to DMP Assistant / Bienvenue sur l'Assistant PGD")
  end

  # rubocop:disable Metrics/AbcSize
  def question_answered(data, user, answer, _options_string)
    @user           = user
    @username       = @user.name
    @answer         = answer
    @question_title = @answer.question.text.to_s
    @plan_title     = @answer.plan.title.to_s
    @template_title = @answer.plan.template.title.to_s
    @data           = data
    @recipient_name = @data['name'].to_s
    @message        = @data['message'].to_s
    @answer_text    = @options_string.to_s

    recipient = User.find_by(email: data['email'])

    LocaleService.with_preferred_locale(recipient) do
      mail(to: data['email'],
           subject: data['subject'])
    end
  end
  # rubocop:enable Metrics/AbcSize

  def sharing_notification(role, user, inviter:)
    @role       = role
    @user       = user
    @user_email = @user.email
    # TODO: Should this be `@user.name(false)`? Currently, @username is just being assigned @user.email
    # (There are several other user.name calls in UserMailer that should be verified as well)
    @username   = @user.name
    @inviter    = inviter
    @link       = url_for(action: 'show', controller: 'plans', id: @role.plan.id)

    LocaleService.with_preferred_locale(@role.user) do
      mail(to: @role.user.email,
           subject: format(_('A Data Management Plan in %{tool_name} has been shared with you'),
                           tool_name: tool_name))
    end
  end

  def permissions_change_notification(role, user)
    return unless user.active?

    @role       = role
    @plan_title = @role.plan.title
    @user       = user
    @recepient = @role.user

    LocaleService.with_preferred_locale(@recepient) do
      mail(to: @recepient.email,
           subject: format(_('Changed permissions on a Data Management Plan in %{tool_name}'),
                           tool_name: tool_name))
    end
  end

  def plan_access_removed(user, plan, current_user)
    return unless user.active?

    @user         = user
    @plan         = plan
    @current_user = current_user

    LocaleService.with_preferred_locale(@user) do
      mail(to: @user.email,
           subject: format(_('Permissions removed on a DMP in %{tool_name}'),
                           tool_name: tool_name))
    end
  end

  def feedback_notification(recipient, plan, requestor)
    return unless recipient.active?

    @user           = requestor
    @plan           = plan
    @recipient      = recipient
    @recipient_name = @recipient.name(false)
    @requestor_name = @user.name(false)
    @plan_name      = @plan.title

    LocaleService.with_preferred_locale(@recipient) do
      mail(to: @recipient.email,
           subject: format(_('%{user_name} has requested feedback on a %{tool_name} plan'),
                           tool_name: tool_name, user_name: @user.name(false)))
    end
  end

  # rubocop:disable Metrics/AbcSize
  def feedback_complete(recipient, plan, requestor)
    return unless recipient.active?

    @requestor_name = requestor.name(false)
    @user           = recipient
    @recipient_name = @user.name(false)
    @plan           = plan
    @phase          = @plan.phases.first
    @plan_name      = @plan.title

    LocaleService.with_preferred_locale(recipient) do
      sender = Rails.configuration.x.organisation.do_not_reply_email ||
               Rails.configuration.x.organisation.email

      mail(to: recipient.email,
           from: sender,
           subject: format(_('%{tool_name}: Expert feedback has been provided for %{plan_title}'),
                           tool_name: tool_name, plan_title: @plan.title))
    end
  end
  # rubocop:enable Metrics/AbcSize

  def plan_visibility(user, plan)
    return unless user.active?

    @user            = user
    @username        = @user.name
    @plan            = plan
    @plan_title      = @plan.title
    @plan_visibility = Plan::VISIBILITY_MESSAGE[@plan.visibility.to_sym]

    LocaleService.with_preferred_locale(@user) do
      mail(to: @user.email,
           subject: format(_('DMP Visibility Changed: %{plan_title}'), plan_title: @plan.title))
    end
  end

  # commenter - User who wrote the comment.
  # plan - Plan for which the comment is associated to
  # answer - Answer commented on
  # rubocop:disable Metrics/AbcSize
  def new_comment(commenter, plan, answer)
    return unless commenter.is_a?(User) && plan.is_a?(Plan)

    owner = plan.owner
    return unless owner.present? && owner.active?

    @commenter       = commenter
    @commenter_name  = @commenter.name
    @plan            = plan
    @plan_title      = @plan.title
    @user_name       = @plan.owner.name
    @answer          = answer
    @question        = @answer.question
    @question_number = @question.number
    @section_title   = @question.section.title
    @phase_id        = @question.section.phase.id
    @phase_link = url_for(action: 'edit', controller: 'plans', id: @plan.id, phase_id: @phase_id)

    LocaleService.with_preferred_locale(@plan.owner) do
      mail(to: @plan.owner.email,
           subject: format(_('%{tool_name}: A new comment was added to %{plan_title}'),
                           tool_name: tool_name, plan_title: @plan.title))
    end
  end
  # rubocop:enable Metrics/AbcSize

  def admin_privileges(user)
    return unless user.active?

    @user      = user
    @username  = @user.name

    LocaleService.with_preferred_locale(@user) do
      mail(to: user.email,
           subject: format(_('Administrator privileges updated in %{tool_name}'),
                           tool_name: tool_name))
    end
  end

  # rubocop:disable Metrics/AbcSize
  def api_credentials(api_client)
    @api_client = api_client
    return unless @api_client.contact_email.present?

    @api_docs = Rails.configuration.x.application.api_documentation_urls[:v1]

    @name = @api_client.contact_name.present? ? @api_client.contact_name : @api_client.contact_email

    recipient = User.find_by(email: @api_client.contact_email) || @api_client.org

    LocaleService.with_preferred_locale(recipient) do
      mail(to: @api_client.contact_email,
           subject: format(_('%{tool_name} API changes'), tool_name: tool_name))
    end
  end
  # rubocop:enable Metrics/AbcSize

  def plan_snapshot_failure_alert(message:, payload:)
    recipient = Rails.configuration.x.organisation.development_email
    return unless recipient.present?

    @message = message
    @payload = payload

    mail(to: recipient,
         subject: format(_('%{tool_name} alert: %{message}'),
                         tool_name: tool_name,
                         message: message))
  end
end
