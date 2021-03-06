/**********************************
 Yurak Sisa Dreams JavaScript 
 ----------------------------
 Javascript library from Yurak Sisa Dreams
 **********************************/
define(function() {

  var rates = {};

  /********************************
   Season Object Constructor
   --------------------------------
   Represents the ratings periods, that is seasons

   @param [String] The season id
   @param [String] The season start (month/day)
   @param [String] The season end (month/day)
   ********************************/
  rates.Season = function(id, start, end) {
  
    this.id = id;
    this.start = start;
    this.end = end;
    
    /* Calculates how many days belong to the Season */
    
    this.days = function (fromDate, toDate) {
    
      var theYear = fromDate.getFullYear().toString();
      
      var startDateStr = this.start + '/' + theYear;
      var endDateStr = this.end + '/' + theYear;

      var startDate = new Date(startDateStr);
      var endDate = new Date(endDateStr);
             
      var days = ( ( ((toDate < endDate ? toDate:endDate) - (fromDate > startDate ? fromDate : startDate)) / (1000 * 60 * 60 * 24) ) + 1 ).toFixed(0) ;
      
      return days;
        	
    };	
  	
  }
  
  /*****************************************************
   Calendar Object Constructor
   -------------------------------
   
   Retrieves information about the session between two dates

   It works retrieving the season and the number of days of each season
   
   For example:

     season 1 01/01 - 03/31
     season 2 04/01 - 04/30

     get_seasons_days(new Date("03/30/2013"), new Date("04/02/2013")) returns

       [{'season':'1', days:2}, {'season':'2', days:2}]

   *****************************************************/
  rates.Calendar = function(seasons) {
  	
  	this.seasons = seasons;
  	  	  	
  	/****
     *
  	 * Gets an array of Objects with two properties: season (the season id) and days (number of days of that season)
     *
  	 ****/  	                  
  	this.get_seasons_days = function (from, to) {
  		
  	   var result = [];
  	   var i = 0; // seasons index
  	  
  	   var fromDate = from;
  	   var toDate = to;  	   
  	
  	   this.checkToDate(toDate, to, year);
  		   	   	   
  	   var seasonsLength = this.seasons.length;
  	   var year = fromDate.getFullYear();
  	   
  	   do {
  	   
  	     var season = this.seasons[i];  	     
  	     var d = season.days(fromDate, toDate);
  	     
  		   if (d > 0) {
  		     fromDate = new Date( season.end + '/' + year.toString() );
  		     result.push ( {'season' : season.id, 'days' : d } );
  		   }
  		 
  		   if (fromDate <= to) {
  		     i++;
  		     // Pass to the next year
  		     if (i == seasonsLength) 	
  		     {
  		   	   i=0;
  		   	   year++;
  		   	   // Configure fromDate
  		   	   fromDate.setDate(1);
  		   	   fromDate.setMonth(0);
  		   	   fromDate.setYear(year);
  		   	   // Configure toDate
  		   	   this.checkToDate(toDate, to, year);
  		     }		
  		   }
  		   		
  	   }
       while (fromDate <= to);
  		
  	   return result;	
  		
  	}
  	
  
    this.checkToDate = function(toDate, to, year) {

  	   if (to.getFullYear() > year) {
  		   toDate.setDate(31);
  		   toDate.setMonth(11);
  		   toDate.setYear(year);	
  	   }
  	   else
  		 {
  		   toDate = to;	
  		 }
    	
    };
  	  	
  	
  }
  
  /**************
   * 
   * Retrieves information about the session between two dates
   *   
   * It works retrieving the first season day 
   *
   *
   * For example:
   *
   *  season 1 01/01 - 03/31
   *  season 2 04/01 - 04/30
   *
   *  get_seasons_days(new Date("03/30/2013"), new Date("04/02/2013")) returns 
   *
   *   [{'season':'1', days:4}]
   */
  rates.FirstSeasonDayCalendar = function(seasons) {
    
    this.seasons = seasons;
    	
  	/****
  	 * Gets an array of seasons and number of days
  	 ****/  	                  
  	this.get_seasons_days = function (from, to) {
  		
  	   var result = [];
  	   var i = 0; // seasons index
  	  
  	   var fromDate = from;
  	   var toDate = to;  	   
  	
  	   this.checkToDate(toDate, to, year);
  		   	   	   
  	   var seasonsLength = this.seasons.length;
  	   var year = fromDate.getFullYear();
  	   
  	   do {
  	   
  	     var season = this.seasons[i];
  	     
  	     var d = season.days(fromDate, toDate);
  	     
  		   if (d > 0) {
  		     fromDate = new Date( season.end + '/' + year.toString() );
  		     result.push ( {'season' : season.id, 'days' : ((to - from) / (1000*60*60*24) + 1).toFixed(0) } );
  		     break;
  		   }
  		 
  		   if (fromDate <= to) {
  		     i++;
  		     // Pass to the next year
  		     if (i == seasonsLength) {
  		   	   i=0;
  		   	   year++;
  		   	   // Configure fromDate
  		   	   fromDate.setDate(1);
  		   	   fromDate.setMonth(0);
  		   	   fromDate.setYear(year);
  		   	   // Configure toDate
  		   	   this.checkToDate(toDate, to, year);
  		     }		
  		   }
  		   		
  	   }
  	   while (fromDate <= to);
  		
  	   return result;	
  		
  	}
  	
  }
  
  rates.FirstSeasonDayCalendar.prototype = new rates.Calendar();
  rates.FirstSeasonDayCalendar.constructor = rates.FirstSeasonDayCalendar;
   
  /***************************
   Factor
   
   It defines a factor to apply depending the number of days 
   
   @param [Number] The days from
   @param [Number] The days to
   @param [Number] The factor (percentage) to apply

   ***************************/
  rates.Factor = function(from, to, factor) {
   
    this.from = from;
    this.to = to;
    this.factor = factor;
    
    /**
     * Check if the factor applies for theses days
     *
     * @param [Numeric] ndays
     * @return [Boolean]
     */   
    this.applies = function(ndays) {
    	
      return (ndays >= from && ndays <= to);	
    	
    }
   
  } 
     
  /*************************
   * Rate Finder
   * -----------------------
   *
   * Rates can be defined like this:
   *
   *  rates = { 
   *    'family1' : { 
   *       'session1': {
   *          // HOW THE PRICE IS REPRESENTED
   *        }
   *    }
   *  }
   *
   *  1. Price by family / session / day
   *
   *  rates = { 
   *    'family1' : { 
   *       'session1': {
   *          price: 1_day_car_price
   *        }
   *    }
   *  }
   *
   * 2. Price by family / session / number of days
   *
   *  rates = { 
   *    'family1' : { 
   *       'session1': {
   *          'upToDays' : 7,
   *          'prices' : {
   *            '1': 1_day_car_price,
   *            '2': 2_days_car_price,
   *            '3': 3_days_car_price,
   *            '4': 4_days_car_price,
   *            '5': 5_days_car_price,
   *            '6': 6_days_car_price,
   *            '7': 7_days_car_price,
   *          },
   *          'extraPrice' : 1_extra_day_car_price               
   *        }
   *    }
   *  }
   *
   */
  rates.RateFinder = function(rates) {
    
    this.rates = rates;
    
    /***
     * Get the rate that matches the family and ndays
     *
     * If a rate has been defined for the family and number of days, take it. Else take the generic rate
     *
     * @param [String] family
     *
     * @param [Numeric] ndays
     *
     * @return [Object] {'session' : {'price' : value}}
     */
    this.get_rate = function(family, ndays) {
    
      var key = family + ndays;
      
      return this.rates[key]?this.rates[key]:this.rates[family];
        
    }
      
  }
  
  /****
   * Optional rate finder
   */
  rates.OptionalRateFinder = function(optionRates) {
    
    this.optionRates = optionRates;
    
    /*
     * Get the rate for the family and option
     *
     * @param [String] family
     * @param [String] option (the optional)
     * @return [Object] the daily price of the option
     *
     */
    this.get_rate = function(family, optional) {

      if (typeof this.optionRates[optional] != 'undefined') { // If option rate is defined by family
        if (typeof this.optionRates[optional][family] != 'undefined') {
          return this.optionRates[optional][family];
        }
        else {
          return this.optionRates[optional];
        }
      }
      
      return null;
      

    }
   
  }

  /***************************
   FactorCalculations
   ***************************/
  rates.FactorFinder = function(factors) {
  
    this.factors = factors;
    
    /**
     get_factor
     ----------
     @param [String] season
       The season
     @param [String] family
       The family       
     @param [Numeric] ndays
       Number of days the customer wants to rent the car
     @return [Numeric]
       The factor which must be applied to the price 
     **/
     this.get_factor = function(season, family, ndays) {
     
       var factor = 1;
       
       for (var i=0;i<this.factors.length;i++) {
       	
       	  if (this.factors[i].applies(ndays)) {
       	  	factor = this.factors[i].factor;
       	  	break;
       	  }
       	
       }
       
       return factor;
     	    	
     }
  	
  } 

  /*******************************
   FixedFactorFinder
   *******************************/
  rates.FixedFactorFinder = function(value) {
     this.value = value;

     this.get_factor = function(season, family, ndays) {
        return this.value;
     }
  }
   
  /*******************************
   FixedFactorFinder
   *******************************/
  rates.FixedSeasonFactorFinder = function(value) {
     this.value = value;

     this.get_factor = function(season, family, ndays) {
        return this.value[season];
     }
  }

  /**
   * Session factor finder (factors defined by session)
   */
  rates.SeasonFactorFinder = function(factors, globalFactors) {

    this.factors = factors;
    this.globalFactors = globalFactors;

    /**
     get_factor
     ----------
     @param [String] season
       The season
     @param [String] family
       The family       
     @param [Numeric] ndays
       Number of days the customer wants to rent the car
     @return [Numeric]
       The factor which must be applied to the price 
     **/
    this.get_factor = function(season, family, ndays) {
      
      var calculationFactors = null;

      if (season && factors[season] && factors[season][family]) {
        calculationFactors = this.factors[season][family];
      }
      
      var finder = new rates.FactorFinder(calculationFactors || this.globalFactors);

      return finder.get_factor(season, family, ndays);

    }

  }
   
  /**
   * PriceCalculatorSimpleRate
   *
   * The rate defines just one price 
   */ 
  rates.PriceCalculatorSimpleRate = function(priceDefinition, ndays) {

    return priceDefinition.price * ndays; 

  }

  /**
   * PriceCalculatorDaysRate
   *
   * Prices has been defined for number of days
   */
  rates.PriceCalculatorDaysRate = function(priceDefinition, ndays) {

    if (ndays <= priceDefinition.upToDays) {
      return priceDefinition.prices[ndays];
    }
    else {
      var extraDays = ndays - priceDefinition.upToDays;
      return priceDefinition.prices[priceDefinition.upToDays] + priceDefinition.extraPrice * extraDays;
    }

  }

  /**
   * Rate calculation based on factors 
   *
   * It's responsable of calculating the renting price
   *
   * @param [Calendar] The calendar
   * @param [RateFinder] The rate finder
   * @param [FactorFinder] The factor to apply
   * @param [OptionalFinder] The optional finder
   * @param [Function] Price calculation system
   *
   **/   
  rates.RateCalculation = function(calendar, rateFinder, factorFinder, optionalFinder, priceCalculationFunction, basePrice) {
  
    this.calendar = calendar;
  	this.rateFinder = rateFinder;
  	this.factorFinder = factorFinder;
    this.optionalFinder = optionalFinder;
    this.priceCalculationFunction = priceCalculationFunction || rates.PriceCalculatorSimpleRate;
  	this.basePrice = basePrice;

  	/**
  	 get_price
  	 ---------
     @param [Date] from
     @param [Date] to
     @param [Object] the families
     @param [Object] the options
     @param [Number] scale
  	 @returns a object which properties are the families and the value is the price 	 
  	 **/
  	this.get_price = function (fromDate, toDate, families, optionals, scale) {
  
      // Get the total number of days
      var ndays = ((toDate - fromDate) / (1000*60*60*24)).toFixed(0); 
      
      // Get the days grouped by season
      var endDate = new Date(toDate);
      endDate.setDate(endDate.getDate() - 1);

      var seasonDays = this.calendar.get_seasons_days(fromDate, endDate);
      
      var firstPeriodSeason = null;
  
      if (seasonDays.length > 0) {
        firstPeriodSeason = seasonDays[0].season;
      }

      var familyLength = families.length;
      var seasonDaysLength = seasonDays.length;
      var result = {};
                 
      // Process the families
      for (var family in families) {
      	var rate = this.rateFinder.get_rate( family, ndays );
        var price = 0;
        var base =  this.basePrice[family] || 0;
                
        // calculate the price taken the seasons into account
      	for (var idxdays = 0; idxdays < seasonDaysLength; idxdays++)
      	{
      	  var season = seasonDays[idxdays].season;
          if (families[family].detailedPrice) {
            price += rates.PriceCalculatorDaysRate(rate[season], seasonDays[idxdays].days);
          }
          else {
            price += rates.PriceCalculatorSimpleRate(rate[season], seasonDays[idxdays].days);
          }
      	}
      	
        // apply factor
        if (!families[family].detailedPrice) {
          if (this.factorFinder != null) {
      	    price = price * this.factorFinder.get_factor(firstPeriodSeason, family, ndays);
          }
        }
        price += base;

        result[family] = new Number(price.toFixed(scale)); 
        
        // apply the optionals
        for (var optional in optionals) {
          var optionalRate = this.optionalFinder.get_rate(family, optional);
          var optionalPrice = 0;
          if (optionalRate != null) {
            optionalPrice = optionalRate.price * ndays;
          }
          result[family][optional] = new Number((price + optionalPrice).toFixed(scale));
        }
      	
      }

      return result;   		
  	}
  	
  }
  
  /* Options (It represents item options) */
  rates.Option = function(id, name, abbr, description) {
    this.id = id;
    this.name = name;
    this.abbr = abbr;
    this.description = description;
  }
  
  /* Extra (It represents the items extras) */
  /* 
      @param [String] The extra id
      @param [String] The extra name
      @param [String] The extra description
      @param [Numeric] Max extra quantity
      @param [Array] The optional that doesn't use the extra
      @param [Boolean] detailed price
      @param [Object] translations
   */
  rates.Extra = function(id, the_name, description, max_quantity, notAcceptedOptionals, detailedPrice, translations) {
  	
    this.id = id;
    this.the_name = the_name;
    this.description = description;
    this.max_quantity = max_quantity;
    this.notAcceptedOptionals = notAcceptedOptionals || [];
    this.detailedPrice = detailedPrice;
    this.translations = translations;

    this.optionalAccepted = function(optional) {
      if (Array.prototype.indexOf) {
        return this.notAcceptedOptionals.indexOf(optional) == -1;
      }
      else {
        return _.indexOf(this.notAcceptedOptionals, optional) == -1;
      }
    }
  }
  
  rates.ExtraCalculation = function(extrasRates, extras) {

    this.extrasRates = extrasRates;
    this.extras = extras;
    
    this.get_extra_rate = function( extra_id, family ) {

      var extraPrices = this.extrasRates[extra_id];

      if (extraPrices[family]) {
        return extraPrices[family];
      }

      return extraPrices;

    }

    /*
     * Calcute the extra price for the period and the family
     */
    this.get_price = function( date_from, date_to, extra_id, family, scale) {
    
       var ndays = ((date_to - date_from) / (1000*60*60*24)).toFixed(0);

       if (ndays > 0) {
         var extraRate = this.get_extra_rate(extra_id, family);
         var price = 0;

         if (this.extras[extra_id].detailedPrice) {
            price = rates.PriceCalculatorDaysRate(extraRate, ndays);
         }
         else {
            price = rates.PriceCalculatorSimpleRate(extraRate, ndays);
         }
         
         if (extraRate.maxPrice > 0) {
           return new Number( Math.min( price, extraRate.maxPrice ).toFixed(scale) );
         }
         return new Number(price).toFixed(scale);
       }

       return 0;

    }

  }

  return rates;

});
