class ApplicationController < ActionController::Base
  include Pagy::Backend

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  private

  # ?page=0 or ?page=abc shows the first page instead of raising Pagy::VariableError
  def pagy_get_page(vars)
    [ super, 1 ].max
  end
end
