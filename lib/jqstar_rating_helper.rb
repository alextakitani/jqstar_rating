module JqStarRating # :nodoc:
  module Helper
    class MissingRateRoute < StandardError
      def to_s
        "Add :member => {:rate => :post} to your routes, or specify a custom url in the options."
      end
    end


    def ratings_for(rateable, *args)
      out=""
      caption=""

      if !flash[:jqstar_js]
        flash[:jqstar_js] = ""
      end
      user = extract_user(*args)

      options = args.extract_options!
      options.reverse_merge!(jqstar_options)

      star = star_value(rateable, options, user)

      if options[:show_caption]
        caption = ", captionEl: $(\"#stars-cap-#{options[:dimension].to_s}\") "
        out = content_tag(:span, "", {:id=>"stars-cap-#{options[:dimension].to_s}"})
      end

      url = respond_to?(url = "rate_#{rateable.class.name.downcase}_path") ? send(url, rateable) : raise(MissingRateRoute)

      default_callback = ", callback: function(ui, type, value) { $.post(\"#{url}\", {stars:value, dimension:'#{options[:dimension]}'}, function(data){ data }, 'script' );  }"

      callback = options[:callback] || default_callback

      flash[:jqstar_js] += " $(\"#stars-wrapper-#{options[:dimension].to_s}\").stars({ split: #{options[:split]},disabled:#{options[:disabled]} #{caption} #{callback} }); "

      out += content_tag(:div, { :id=>"stars-wrapper-#{options[:dimension].to_s}"}) do
        (1..rateable.class.max_rate_value).collect do |i|
          option_value = i.to_f / options[:split].to_f
          html_options = { "type" => "radio",
                           "id" => "rad-"+options[:dimension].to_s+ i.to_s,
                           "value" => (option_value).to_s
          }

          html_options["checked"] = "checked" if star == option_value

          tag(:input, html_options) + "&nbsp;"
        end

      end

    end

#    Average: <span id="fake-stars-cap"></span>
#    <div id="fake-stars-off" class="stars-off" style="width:80px">
#       <div id="fake-stars-on" class="stars-on"></div>
#   </div>
#   average works with the width to correctly draw the stars. more info at
#   http://orkans-tmp.22web.net/star_rating/
#


    def avg_ratings_for(rateable, *args)

      if !flash[:jqstar_js]
        flash[:jqstar_js] = ""
      end

      options = args.extract_options!

      flash[:jqstar_js] += avg_ratings_js(rateable, options)

      out = content_tag(:span, "", {:id=>"stars-cap-avg-#{options[:dimension].to_s}"})

      divon = content_tag(:div, "", {:id=>"stars-cap-avg-on-#{options[:dimension].to_s}",
                                     :class=>"stars-on"
      })

      out += content_tag(:div, divon, {:id=>"stars-cap-avg-off-#{options[:dimension].to_s}",
                                       :class=>"stars-off",
                                       :style=>"width:#{options[:width]}"
      })
    end

    def jsqtar_js
      if not flash[:jqstar_js].to_s.empty?
        out = content_tag(:script, flash[:jqstar_js].to_s, {:type=>"text/javascript"} )
        flash[:jqstar_js] = ""
        out
      end
    end

    def avg_ratings_js(rateable, *args)

      options = args.extract_options!
      star = rateable.rate_average(true, options[:dimension])
      votes = rateable.total_rates(options[:dimension])
      out=""
      out << " $('#stars-cap-avg-on-#{options[:dimension].to_s}').width(Math.round( $('#stars-cap-avg-off-#{options[:dimension].to_s}').width() / #{options[:stars]} * parseFloat(#{star}) )); "
      out << " $('#stars-cap-avg-#{options[:dimension].to_s}').text(#{star} + ' (' + #{votes} + ')'); "
    end


    private
    def star_value(rateable, options, user)
      star = 0
      star = rateable.rate_by(user, options[:dimension]).stars if user && rateable.rated_by?(user, options[:dimension])
    end

    def jqstar_options
      {
              :force_dynamic => false,
              :html => {},
              :remote_options => {:method => :post},
              :split => 1,
              :disabled=>false,
              :show_caption=>false
      }
    end


    # Extracts the hash options and returns the user instance.
    def extract_user(*args)
      user = if args.first.is_a?User
        args.shift
      end
      user
    end
  end

end

class ActionView::Base
  include JqStarRating::Helper
end
