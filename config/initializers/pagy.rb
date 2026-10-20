# frozen_string_literal: true

# A page past the end (an old link, or people unfollowed since) shows the last page
# instead of raising Pagy::OverflowError (a 500 error page)
require "pagy/extras/overflow"
Pagy::DEFAULT[:overflow] = :last_page
