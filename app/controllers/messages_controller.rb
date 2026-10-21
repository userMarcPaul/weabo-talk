# frozen_string_literal: true

# Direct messages: under construction, the page only says so for now
class MessagesController < ApplicationController
  before_action :authenticate_user!

  # GET /messages
  def index
  end
end
