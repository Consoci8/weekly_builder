# WeeklyCalendar
module WeeklyHelper

  def weekly_calendar(objects, *args)
    options = args.last.is_a?(Hash) ? args.pop : {}
    date = options[:date] || Time.now
    start_date = Date.new(date.year, date.month, date.day)
    end_date = Date.new(date.year, date.month, date.day) + 6
    concat(tag("div", :id => "week"))
    yield WeeklyBuilder.new(objects || [], self, options, start_date, end_date)
    concat("</div>")
    if options[:include_24_hours] == true
      concat("<b><a href='?business_hours=true&start_date=#{start_date}'>Business Hours</a> | <a href='?business_hours=false&start_date=#{start_date}'>24-Hours</a></b>")
    end
  end

  # Displaying just the hours between the start date and the end date
  # You could also pass additional hash parameters
  #
  # ==== Examples in your view
  # weekly_calendar_with_end_date(@bookings, :start_date => @date, :end_date => @end_date, :include_24_hours => true, :values => {:user_id => params[:user_id} ) do |w|
  #   # do something
  # end
  #
  # Note: You can't use this with weekly_links
  def weekly_calendar_with_end_date(objects, *args)
    options = args.last.is_a?(Hash) ? args.pop : {}
    date = options[:start_date] || Time.now
    e_date = options[:end_date]
    start_date = Date.new(date.year, date.month, date.day)
    end_date =  Date.new(e_date.year, e_date.month, e_date.day)
    concat(tag("div", :id => "week"))
    yield WeeklyBuilder.new(objects || [], self, options, start_date, end_date)
    concat("</div>")
    if options[:include_24_hours] == true
      if !options[:values].blank?
        values = "&" +options[:values].map {|k,v| "#{k}=#{v}" }.join("&").to_s
      end
      concat("<b><a href='?business_hours=true&start_date=#{start_date}#{values}'>Business Hours</a> | <a href='?business_hours=false&start_date=#{start_date}#{values}'>24-Hours</a></b>")
    end
  end

  def weekly_links(options)
    date = options[:date]
    start_date = Date.new(date.year, date.month, date.day)
    end_date = Date.new(date.year, date.month, date.day) + 7
    concat("<a href='?start_date=#{start_date - 7}?user_id='>« Previous Week</a> ")
    concat("#{start_date.strftime("%B %d -")} #{end_date.strftime("%B %d")} #{start_date.year}")
    concat(" <a href='?start_date=#{start_date + 7}?user_id='>Next Week »</a>")
  end

  class WeeklyBuilder
    include ::ActionView::Helpers::TagHelper

    def initialize(objects, template, options, start_date, end_date)
      raise ArgumentError, "WeeklyBuilder expects an Array but found a #{objects.inspect}" unless objects.is_a? Array
      @objects, @template, @options, @start_date, @end_date = objects, template, options, start_date, end_date
    end

    def week(options = {})
      days
      if options[:business_hours] == "true" or options[:business_hours].blank?
        hours = ["6am","7am","8am","9am","10am","11am","12pm","1pm","2pm","3pm","4pm","5pm","6pm","7pm","8pm"]
        header_row = "header_row"
        day_row = "day_row"
        grid = "grid"
        start_hour = 6
        end_hour = 20
      else
        hours = ["1am","2am","3am","4am","5am","6am","7am","8am","9am","10am","11am","12pm","1pm","2pm","3pm","4pm","5pm","6pm","7pm","8pm","9pm","10pm","11pm","12am"]
        header_row = "full_header_row"
        day_row = "full_day_row"
        grid = "full_grid"
        start_hour = 1
        end_hour = 24
      end

      concat(tag("div", :id => "hours"))
      concat(tag("div", :id => header_row))
      for hour in hours
        header_box = "<b>#{hour}</b>"
        concat(content_tag("div", header_box, :id => "header_box"))
      end
      concat("</div>")

      concat(tag("div", :id => grid))
      for day in @start_date..@end_date
        concat(tag("div", :id => day_row))
        for event in @objects
          if event.start_date.strftime('%j').to_s == day.strftime('%j').to_s
            # This means he's not available at this slot time.
            if event.start_date.strftime('%H').to_i >= start_hour and event.end_date.strftime('%H').to_i <= end_hour
              concat(tag("div", :id => "week_event", :style =>"left:#{left(event.start_date,options[:business_hours])}px;width:#{width(event.start_date,event.end_date)}px;", :onclick => "location.href='/events/#{event.id}';"))
              truncate = truncate_width(width(event.start_date,event.end_date))
              yield(event,truncate)
              concat("</div>")
            end
          end
        end

        # Make all other areas clickable
        if options[:clickable_hours] == true
          hours.each do |h|
            concat(content_tag("div", '', :id => "week_eventx", :onclick => "alert('hello #{h}');"))
          end
        end

        concat("</div>")
      end
      concat("</div>")
      concat("</div>")
    end

    def days
      concat(tag("div", :id => "days"))
      concat(content_tag("div", "", :id => "placeholder"))
      for day in @start_date..@end_date
        concat(tag("div", :id => "day"))
        concat(content_tag("b", day.strftime('%A')))
        concat(tag("br"))
        concat(day.strftime('%B %d'))
        concat("</div>")
      end
      concat("</div>")
    end

    private

    def concat(tag)
      @template.concat(tag)
    end

    def left(starts_at,business_hours)
      if business_hours == "true" or business_hours.blank?
        minutes = starts_at.strftime('%M').to_f * 1.25
        hour = starts_at.strftime('%H').to_f - 6
      else
        minutes = starts_at.strftime('%M').to_f * 1.25
        hour = starts_at.strftime('%H').to_f - 1
      end
      left = (hour * 75) + minutes
    end

    def width(starts_at,ends_at)
      #example 3:30 - 5:30
      start_hours = starts_at.strftime('%H').to_i * 60 # 3 * 60 = 180
      start_minutes = starts_at.strftime('%M').to_i + start_hours # 30 + 180 = 210
      end_hours = ends_at.strftime('%H').to_i * 60 # 5 * 60 = 300
      end_minutes = ends_at.strftime('%M').to_i + end_hours # 30 + 300 = 330
      difference =  (end_minutes.to_i - start_minutes.to_i) * 1.25 # (330 - 180) = 150 * 1.25 = 187.5

      unless difference < 60
        width = difference - 12
      else
        width = 63 #default width (75px minus padding+border)
      end
    end

    def truncate_width(width)
      hours = width / 63
      truncate_width = 20 * hours
    end
  end
end
