# frozen_string_literal: true

module OrgAdmin
  # Controller that handles creating new versions of Phases
  class PhaseVersionsController < ApplicationController
    include Versionable

    # POST /org_admin/templates/:template_id/phases/:phase_id/versions
    def create
      @phase = Phase.find(params[:phase_id])
      authorize @phase
      @new_phase = get_modifiable(@phase)
      flash[:notice] = if @new_phase == @phase
                         _('This template is already a draft')
                       else
                         _('New version of Template created')
                       end
      redirect_to org_admin_template_phase_url(@new_phase.template, @new_phase)
    end
  end
end
