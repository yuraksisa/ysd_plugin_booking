module Sinatra
  module YitoExtension
    #
    # Booking Traslation REST API
    #
    module BookingTranslationRESTApi

      def self.registered(app)

        #
        # Helpers
        #
        app.helpers do

          #
          # Prepare a content translation for the GUI
          #
          def prepare_translation(translation, language_code)
            result = {}
            translation.get_translated_attributes(language_code).each do |ct_term|
              result.store(ct_term.concept.to_sym, ct_term.translated_text)
            end
            result
          end

        end

        # ------------------------ Category translation -----------------------------
        
        #
        # Retrieve a booking category translation
        #
        app.get "/api/translation/:language/booking/category/:category_id" do

          result = {:language => params[:language], :category_id => params[:category_id] }

          if category_translation=::Yito::Model::Booking::Translation::BookingCategoryTranslation.get(params[:category_id])
            result.merge!(prepare_translation(category_translation, params[:language]))
          end

          status 200
          content_type :json
          result.to_json

        end

        #
        # Updates booking category translation
        #
        app.put "/api/translation/booking/category" do

          request.body.rewind
          translation_request = JSON.parse(URI.unescape(request.body.read))

          language_code = translation_request.delete('language')
          category_id = translation_request.delete('category_id')

          category_translation = ::Yito::Model::Booking::Translation::BookingCategoryTranslation.create_or_update(
                                    category_id, language_code, translation_request)

          status 200
          content_type :json
          prepare_translation(category_translation, language_code).to_json

        end

        # ------------------------ Extra translation --------------------------------

        #
        # Retrieve a booking extra translation
        #
        app.get "/api/translation/:language/booking/extra/:extra_id" do

          result = {:language => params[:language], :extra_id => params[:extra_id] }

          if extra_translation=::Yito::Model::Booking::Translation::BookingExtraTranslation.get(params[:extra_id])
            result.merge!(prepare_translation(extra_translation, params[:language]))
          end

          status 200
          content_type :json
          result.to_json

        end

        #
        # Updates booking category translation
        #
        app.put "/api/translation/booking/extra" do

          request.body.rewind
          translation_request = JSON.parse(URI.unescape(request.body.read))

          language_code = translation_request.delete('language')
          extra_id = translation_request.delete('extra_id')

          extra_translation = ::Yito::Model::Booking::Translation::BookingExtraTranslation.create_or_update(
              extra_id, language_code, translation_request)

          status 200
          content_type :json
          prepare_translation(extra_translation, language_code).to_json

        end

        # ------------------------ Pickup / return place translation --------------------------------

        #
        # Retrieve a booking pickup/return place translation
        #
        app.get "/api/translation/:language/booking/pickup-return-place/:id" do

          result = {:language => params[:language], :id => params[:id] }

          if pickup_return_place_translation=::Yito::Model::Booking::Translation::BookingPickupReturnPlaceTranslation.get(params[:id])
            result.merge!(prepare_translation(pickup_return_place_translation, params[:language]))
          end

          status 200
          content_type :json
          result.to_json

        end

        #
        # Updates booking pickup/return place translation
        #
        app.put "/api/translation/booking/pickup-return-place" do

          request.body.rewind
          translation_request = JSON.parse(URI.unescape(request.body.read))

          language_code = translation_request.delete('language')
          id = translation_request.delete('id')

          pickup_return_place_translation = ::Yito::Model::Booking::Translation::BookingPickupReturnPlaceTranslation.create_or_update(
              id, language_code, translation_request)

          status 200
          content_type :json
          prepare_translation(pickup_return_place_translation, language_code).to_json

        end

        # ------------------------ Activity translation -----------------------------

        #
        # Retrieve a booking category translation
        #
        app.get "/api/translation/:language/booking/activity/:activity_id" do

          result = {:language => params[:language], :activity_id => params[:activity_id] }

          if activity_translation=::Yito::Model::Booking::Translation::BookingActivityTranslation.get(params[:activity_id])
            result.merge!(prepare_translation(activity_translation, params[:language]))
          end

          status 200
          content_type :json
          result.to_json

        end

        #
        # Updates booking category translation
        #
        app.put "/api/translation/booking/activity" do

          request.body.rewind
          translation_request = JSON.parse(URI.unescape(request.body.read))

          language_code = translation_request.delete('language')
          activity_id = translation_request.delete('activity_id')

          activity_translation = ::Yito::Model::Booking::Translation::BookingActivityTranslation.create_or_update(
              activity_id, language_code, translation_request)

          status 200
          content_type :json
          prepare_translation(activity_translation, language_code).to_json

        end

      end

    end
  end
end  