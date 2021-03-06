class AvailabilityZoneController < ApplicationController
  before_action :check_privileges
  before_action :get_session_data
  after_action :cleanup_action
  after_action :set_session_data

  include Mixins::GenericListMixin
  include Mixins::GenericSessionMixin
  include Mixins::MoreShowActions
  include Mixins::GenericShowMixin

  def self.display_methods
    %w(ems_cloud instances cloud_volumes)
  end

  # handle buttons pressed on the button bar
  def button
    @edit = session[:edit]                          # Restore @edit for adv search box

    params[:display] = @display if ["images", "instances"].include?(@display)  # Were we displaying vms/hosts/storages
    params[:page] = @current_page unless @current_page.nil?   # Save current page for list refresh

    if params[:pressed].starts_with?("image_", # Handle buttons from sub-items screen
                                     "instance_")

      pfx = pfx_for_vm_button_pressed(params[:pressed])
      process_vm_buttons(pfx)

      # Control transferred to another screen, so return
      return if ["#{pfx}_policy_sim", "#{pfx}_compare", "#{pfx}_tag",
                 "#{pfx}_retire", "#{pfx}_protect", "#{pfx}_ownership",
                 "#{pfx}_refresh", "#{pfx}_right_size",
                 "#{pfx}_reconfigure"].include?(params[:pressed]) &&
                @flash_array.nil?

      unless ["#{pfx}_edit", "#{pfx}_miq_request_new", "#{pfx}_clone",
              "#{pfx}_migrate", "#{pfx}_publish"].include?(params[:pressed])
        @refresh_div = "main_div"
        @refresh_partial = "layouts/gtl"
        show                                                        # Handle VMs buttons
      end
    else
      tag(AvailabilityZone) if params[:pressed] == "availability_zone_tag"
      return if ["availability_zone_tag"].include?(params[:pressed]) &&
                @flash_array.nil? # Tag screen showing, so return
    end

    unless @refresh_partial # if no button handler ran, show not implemented msg
      add_flash(_("Button not yet implemented"), :error)
      @refresh_partial = "layouts/flash_msg"
      @refresh_div = "flash_msg_div"
    end

    if params[:pressed].ends_with?("_edit") || ["#{pfx}_miq_request_new", "#{pfx}_clone",
                                                "#{pfx}_migrate", "#{pfx}_publish"].include?(params[:pressed])
      render_or_redirect_partial(pfx)
    else
      if @refresh_div == "main_div" && @lastaction == "show_list"
        replace_gtl_main_div
      else
        render :update do |page|
          page << javascript_prologue
          unless @refresh_partial.nil?
            if @refresh_div == "flash_msg_div"
              page.replace(@refresh_div, :partial => @refresh_partial)
            else
              if ["images", "instances"].include?(@display) # If displaying vms, action_url s/b show
                page << "miqSetButtons(0, 'center_tb');"
                page.replace_html("main_div", :partial => "layouts/gtl", :locals => {:action_url => "show/#{@availability_zone.id}"})
              else
                page.replace_html(@refresh_div, :partial => @refresh_partial)
              end
            end
          end
        end
      end
    end
  end

  private

  def textual_group_list
    [%i(relationships), %i(availability_zone_totals tags)]
  end
  helper_method :textual_group_list

  menu_section :clo
end
