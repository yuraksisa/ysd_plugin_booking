module Sinatra
  module YSD
    module BookingManagementRESTApiHelper

      #
      # Build the planning conditions to retrieve confirmed bookings in a month/year
      #
      def booking_planning_conditions(params)
        today = DateTime.now
        month = today.month
        year = today.year

        if params[:month] and params[:month].to_i > 0 and params[:month].to_i < 13
          month = params[:month].to_i
        end

        if params[:year]
          year = params[:year].to_i
        end

        from = DateTime.new(year, month, 1, 0, 0, 0, 0)
        to = (from >> 1) - 1

        condition = Conditions::JoinComparison.new('$and',
                                                   [Conditions::Comparison.new(:status, '$in', [:confirmed,:in_progress,:done]),
                                                    Conditions::JoinComparison.new('$or',
                                                                                   [Conditions::JoinComparison.new('$and',
                                                                                                                   [Conditions::Comparison.new(:date_from,'$lte', from),
                                                                                                                    Conditions::Comparison.new(:date_to,'$gte', from)
                                                                                                                   ]),
                                                                                    Conditions::JoinComparison.new('$and',
                                                                                                                   [Conditions::Comparison.new(:date_from,'$lte', to),
                                                                                                                    Conditions::Comparison.new(:date_to,'$gte', to)
                                                                                                                   ]),
                                                                                    Conditions::JoinComparison.new('$and',
                                                                                                                   [Conditions::Comparison.new(:date_from,'$lte', from),
                                                                                                                    Conditions::Comparison.new(:date_to,'$gte', to)
                                                                                                                   ]),
                                                                                    Conditions::JoinComparison.new('$and',
                                                                                                                   [Conditions::Comparison.new(:date_from, '$gte', from),
                                                                                                                    Conditions::Comparison.new(:date_to, '$lte', to)])
                                                                                   ]
                                                    ),
                                                   ]
        )
      end

      #
      # Build the conditions to get confirmed bookings that must be serve in a month/year
      #
      def booking_confirmed_conditions(params)
        today = DateTime.now
        month = today.month
        year = today.year

        if params[:month] and params[:month].to_i > 0 and params[:month].to_i < 13
          month = params[:month].to_i
        end

        if params[:year]
          year = params[:year].to_i
        end

        from = DateTime.new(year, month, 1, 0, 0, 0, 0)
        to = (from >> 1) - 1

        condition = Conditions::JoinComparison.new('$and',
                                                   [Conditions::Comparison.new(:status, '$in', [:confirmed,:in_progress,:done]),
                                                    Conditions::JoinComparison.new('$or',
                                                                                   [Conditions::JoinComparison.new('$and',
                                                                                                                   [Conditions::Comparison.new(:date_from,'$lte', from),
                                                                                                                    Conditions::Comparison.new(:date_to,'$gte', from)
                                                                                                                   ]),
                                                                                    Conditions::JoinComparison.new('$and',
                                                                                                                   [Conditions::Comparison.new(:date_from,'$lte', to),
                                                                                                                    Conditions::Comparison.new(:date_to,'$gte', to)
                                                                                                                   ]),
                                                                                    Conditions::JoinComparison.new('$and',
                                                                                                                   [Conditions::Comparison.new(:date_from,'$lte', from),
                                                                                                                    Conditions::Comparison.new(:date_to,'$gte', to)
                                                                                                                   ]),
                                                                                    Conditions::JoinComparison.new('$and',
                                                                                                                   [Conditions::Comparison.new(:date_from, '$gte', from),
                                                                                                                    Conditions::Comparison.new(:date_to, '$lte', to)])
                                                                                   ]
                                                    ),
                                                   ]
        )

      end

    end
  end
end