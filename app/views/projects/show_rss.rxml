xml.rss('version' => '2.0') do
  xml.channel do
    xml.title("CruiseControl RSS feed for #{@project.name}")
    xml.link(url_for(:only_path => false, :controller => 'projects', :action => 'show', :id => @project))
    xml.language('en-us')
    xml.ttl('10')

    last_build = @project.last_complete_build
    xml.item do
      xml.title(rss_title(@project, last_build))
      # the <pre> tag is not part of the RSS schema, and must be escaped in the feed
      xml.description("<pre>#{rss_description(@project, last_build)}</pre>")
      xml.pubDate(rss_pub_date(last_build))
      xml.guid(rss_link(@project, last_build))
      xml.link(rss_link(@project, last_build))
    end

  end
end
