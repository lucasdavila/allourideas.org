class EarlsController < ApplicationController
  #caches_page :show
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::AssetTagHelper
  require 'fastercsv'
  before_filter :dumb_cleartext_authentication, :except => :export_list

  def show
    session[:welcome_msg] = @earl.welcome_message.blank? ? nil: @earl.welcome_message
    
    if @earl
      unless @earl.active?
        flash[:notice] = t('questions.not_active_error')
        redirect_to '/' and return
      end
      

      if params[:locale].nil? && @earl.default_lang != I18n.default_locale.to_s
	      I18n.locale = @earl.default_lang

	      redirect_to :action => :show, :controller => :earls, :id => @earl.name and return
      end

      begin
      
      show_params = {:with_prompt => true, 
		     :with_appearance => true, 
		     :with_visitor_stats => true,
		     :visitor_identifier => request.session_options[:id]}

      show_params.merge!({:future_prompts => {:number => 1}, :with_average_votes => true}) if @photocracy

      if !@photocracy
              @ab_show_average = Abingo.test("#{@earl.name}_#{@earl.question_id}_leveling_feedback_with_5_treatments", ["no_feedback", "no_adjective", "with_adjective", "with_votes_only", "with_average"]) 
	      show_params.merge!({:with_average_votes => true}) if @ab_show_average == "with_average"
      end

      @question = Question.find(@earl.question_id, :params => show_params)

      #reimplement in some way
      rescue ActiveResource::ResourceConflict
        flash[:error] = "This idea marketplace does not have enough active #{@photocracy ? 'photos' : 'ideas'}. Please contact the owner of this marketplace to resolve this situation"
        redirect_to "/" and return
      end


       logger.info "inside questions#show " + @question.inspect

       # we can probably make this into one api call
       @prompt = Prompt.find(@question.attributes['picked_prompt_id'], :params => {:question_id => @question.id})

       @right_choice_text = @prompt.right_choice_text
       @left_choice_text = @prompt.left_choice_text
       @left_choice_id = @prompt.left_choice_id
       @right_choice_id = @prompt.right_choice_id

       if @photocracy
          if params[:crossfade]
            @vote_crossfade_transition = params[:crossfade] == 'true'
	    if params[:crossfade_time]
	       @crossfade_time = params[:crossfade_time]
	    end
          else
	    crossfade_treatments = ["true_250", "true_500", "true_750", "false_250", "false_500", "false_750"]
	    crossfade, time = ab_test("#{@earl.name}_#{@earl.question_id}_vote_faster_crossfade_and_time_transition", crossfade_treatments, :conversion => "voted").split("_")
            @vote_crossfade_transition = crossfade == 'true'
	    @crossfade_time = time
          end

	  if params[:show_average_votes]
            @show_average_votes = params[:crossfade] == 'true'
	  else
	    @show_average_votes = ab_test("#{@earl.name}_#{@earl.question_id}_show_average_votes", [false, true], :conversion => "voted")
	  end

          @right_choice_photo = Photo.find(@right_choice_text)
          @left_choice_photo = Photo.find(@left_choice_text)
          @future_right_choice_photo = Photo.find(@question.attributes['future_right_choice_text_1'])
          @future_left_choice_photo = Photo.find(@question.attributes['future_left_choice_text_1'])
       end

       if @widget    
         # Define these here because of bug with ie6 css when color parameters are not defined
         @text_on_white = "#555555"
         @lighter_text_on_white = "#797979"
         @vote_button_hover_color = "#2B88AD"
         @tab_hover_color = "#A3D4E8"
         @flag_text_color = "#54AFE2"
         @vote_button_color = "#3198c1" 
         @submit_button_color = "#01bb00"
         @submit_button_hover_color = "#228b53"
         @cant_decide_button_color = "#C5C5C5"
         @submit_button_hover_color = "#B1B1B1"
         @add_idea_button_color = "#01bb00"
         @add_idea_button_hover_color = "#228b53"
         @question_text_color = "#000000"
         @text_on_color = "#FFFFFF"

         if (text_on_white = params[:text_on_white])
           lighter_text = alter_color(text_on_white, 1.1)  
           @text_on_white = "##{text_on_white}"  
           @lighter_text_on_white = "##{lighter_text}" 
	       end

         if (vote_button = params[:vote_button])
           vote_button_hover = alter_color(vote_button, 0.8)
           @vote_button_color = "##{vote_button}"          
           @vote_button_hover_color = "##{vote_button_hover}"
	       end

         if (tab_hover = params[:tab_hover])
           @tab_hover_color = "##{tab_hover}"
         end

         if (flag_text = params[:flag_text])
           @flag_text_color = "##{flag_text}"    
	       end

         if (submit_button = params[:submit_button])
           submit_button_hover = alter_color(submit_button, 0.8)
           @submit_button_color = "##{submit_button}"  
           @submit_button_hover_color = "##{submit_button_hover}"  
	       end

         if (cant_decide_button = params[:cant_decide_button])
           cant_decide_button_hover = alter_color(cant_decide_button, 0.8)
           @cant_decide_button_color = "##{cant_decide_button}"  
           @cant_decide_button_hover_color = "##{cant_decide_button_hover}"  
	       end

         if (add_idea_button = params[:add_idea_button])
           add_idea_button_hover = alter_color(add_idea_button, 0.8)  
           @add_idea_button_color = "##{add_idea_button}"  
           @add_idea_button_hover_color = "##{add_idea_button_hover}"  
	       end

         if (question_text = params[:question_text])
           @question_text_color = "##{question_text}"  
	       end

         if (text_on_color = params[:text_on_color])
           @text_on_color = "##{text_on_color}"  
         end

       end
       @ab_test_name = (params[:id] == 'studentgovernment') ? "studgov_test_size_of_X_votes_on_Y_ideas2" : 
       								"#{@earl.name}_#{@earl.question_id}_test_size_of_X_votes_on_Y_ideas"	       
       @ab_test_ideas_text_name = "#{@earl.name}_#{@earl.question_id}_test_contents_of_add_idea_button"

      if wikipedia?
        # wikipedia ideas are prepended by a 4 character integer
        # that represents their image id
        @left_image_id = @left_choice_text.split('-',2)[0]
        @right_image_id = @right_choice_text.split('-',2)[0]
        @left_choice_text = @left_choice_text.split('-',2)[1]
        @right_choice_text = @right_choice_text.split('-',2)[1]
        @images = {}
        image_dir = "public/images/wikipedia/ad/"
        fullsize_image_paths = Dir.glob("#{image_dir}[0-9][0-9][0-9][0-9].png").map{|i| i.sub(/^public/, '') }
        thumbnail_image_paths = Dir.glob("#{image_dir}[0-9][0-9][0-9][0-9]-thumb.png").map{|i| i.sub(/^public/, '') }
        @fullsize_images = {}
        fullsize_image_paths.each do |image|
          @fullsize_images[File.basename(image, '.png')] = image_path(image)
        end
        @thumbnail_images = {}
        thumbnail_image_paths.each do |image|
          @thumbnail_images[File.basename(image, '-thumb.png')] = image_path(image)
        end
      
        
        render(:template => 'wikipedia/earls_show', :layout => '/wikipedia/layout') && return
      end
    else
      redirect_to('/') and return
    end
  end

  # Perhaps this function should be moved somewhere else?
  # Darkens or lightens "color" (hex string) by a factor of "amount"
  def alter_color(color, amount)
    # Parse hex color, convert to int, multiply by amount, convert back to hex, prepend any necessary 0's, concatenate to reform color
     r = color[0..1].to_i(16) * amount
     g = color[2..3].to_i(16) * amount
     b = color[4..5].to_i(16) * amount

     if (r < 0)
      r = 0;
     elsif (r > 255)
      r = 255;
     end
     if (g < 0)
      g = 0;
     elsif (g > 255)
      g = 255; 
     end
     if (b < 0)
      b = 0;
     elsif (b > 255)
      b = 255;   
     end

     return r.floor.to_s(16).rjust(2, '0') + g.floor.to_s(16).rjust(2, '0') + b.floor.to_s(16).rjust(2, '0')
  end
  
  def export_list
     authenticate

     unless current_user.admin?
       flash[:notice] = "You are not authorized to export data"
       redirect_to( {:action => :index, :controller => :home}) and return
     end
     @earls= Earl.find(:all)
     outfile = "question_list_" + Time.now.strftime("%m-%d-%Y") + ".csv"
     headers = ['Earl ID', 'Name', 'Question ID', 'Creator ID', 'Active', 'Has Logo', 'Has Password',
                      'Created at', 'Updated at']

     csv_data = FasterCSV.generate do |csv|
        csv << headers
        @earls.each do |e|
           csv << [ e.id, e.name, e.question_id, e.user_id, e.active, !e.logo_file_name.nil?, ! (e.pass.nil? || e.pass.empty?),
                   e.created_at, e.updated_at]
  	end
     end
    send_data(csv_data,
        :type => 'text/csv; charset=iso-8859-1; header=present',
        :disposition => "attachment; filename=#{outfile}")
  end
  
  
  protected

  def dumb_cleartext_authentication
    @earl = Earl.find_by_name(params[:id])
    redirect_to('/') and return unless @earl
    unless @earl.pass.blank?
      authenticate_or_request_with_http_basic(t('questions.owner_password_exp')) do |user_name, password|
        (user_name == @earl.name) && (password == @earl.pass)
      end
    end
  end
end

# @question = Question.find_by_name(params[:id]) #the question has a prompt id with it
#  #logger.info "inside questions#show " + Question.find(@question.id).inspect
#  @prompt = Prompt.find(@question.attributes['picked_prompt_id'], :params => {:question_id => @question.id})
#  session[:current_prompt_id] = @question.attributes['picked_prompt_id']
#  #@items = @question.items
#  @right_choice_text = @prompt.right_choice_text
#  @left_choice_text = @prompt.left_choice_text
#  @item_count = @question.attributes['item_count']
#  @votes_count = @question.attributes['votes_count']
