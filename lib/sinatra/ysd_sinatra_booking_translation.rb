module Sinatra
  module YitoExtension
    #
    # Traslation application
    #
    module BookingTranslation

      def self.registered(app)

        #
        # Category traslation page
        #
        app.get "/admin/booking/translate/category/:category_id" do

          language_code = if language = ::Model::Translation::TranslationLanguage.find_translatable_languages.first
                            language.code
                          end
          load_page :translate_booking_category, locals: {category_id: params[:category_id], 
                                                          language: language_code}


        end

        #
        # Extra traslation page
        #
        app.get "/admin/booking/translate/extra/:extra_id" do

          language_code = if language = ::Model::Translation::TranslationLanguage.find_translatable_languages.first
                            language.code
                          end
          load_page :translate_booking_extra, locals: {extra_id: params[:extra_id],
                                                       language: language_code}
          
        end

        #
        # Activity traslation page
        #
        app.get "/admin/booking/translate/activity/:activity_id" do

          language_code = if language = ::Model::Translation::TranslationLanguage.find_translatable_languages.first
                            language.code
                          end
          load_page :translate_booking_activity, locals: {activity_id: params[:activity_id],
                                                          language: language_code}

        end

        #
        # Pickup / return place translation
        #
        app.get "/admin/booking/translate/pickup-return-place/:id" do
          language_code = if language = ::Model::Translation::TranslationLanguage.find_translatable_languages.first
                            language.code
                          end
          load_page :translate_booking_pickup_return_place, locals: {id: params[:id],
                                                                     language: language_code}
        end

      end

    end
  end
end