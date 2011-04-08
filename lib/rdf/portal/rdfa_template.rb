# Default HAML templates used for generating output from the writer
module RDF::Portal
  DISTILER_HAML = {
    # Document
    # Locals: language, title, profile, prefix, base, subjects
    # Yield: subjects.each
    :doc => %q(
      !!! XML
      !!! 5
      %html{:xmlns => "http://www.w3.org/1999/xhtml", :lang => lang, :profile => profile, :prefix => prefix}
        - if base || title
          %head
            - if base
              %base{:href => base}
            - if title
              %title= title
            %link{:rel => "stylesheet", :href => "--root--/css/distiller.css", :type => "text/css"}
            %script{:src => "https://ajax.googleapis.com/ajax/libs/jquery/1.5.1/jquery.min.js", :type => "text/javascript"}
            %script{:src => "--root--/js/distiller.js", :type => "text/javascript"}
        %body
          - if base
            %p= "RDFa serialization URI base: &lt;#{base}&gt;"
          - subjects.each do |subject|
            != yield(subject)
          %footer
            %p= "Written by <a href='http://rdf.rubyforge.org/rdfa'>RDF::RDFa</a> version #{RDF::RDFa::VERSION}"
    ),

    # Output for non-leaf resources
    # Note that @about may be omitted for Nodes that are not referenced
    #
    # If _rel_ and _resource_ are not nil, the tag will be written relative
    # to a previous subject. If _element_ is :li, the tag will be written
    # with <li> instead of <div>.
    #
    # Note that @rel and @resource can be used together, or @about and @typeof, but
    # not both.
    #
    # Locals: subject, typeof, predicates, rel, element
    # Yield: predicates.each
    :subject => %q(
      - if element == :li
        %td{:about => get_curie(subject), :typeof => typeof}
          - if typeof
            %span.type!= typeof
          - predicates.each do |predicate|
            != yield(predicate)
      - elsif rel && typeof
        %td{:rel => get_curie(rel)}
          %div{:about => get_curie(subject), :typeof => typeof}
            %span.type!= typeof
            - predicates.each do |predicate|
              != yield(predicate)
      - elsif rel
        %td{:rel => get_curie(rel), :resource => get_curie(subject)}
          - predicates.each do |predicate|
            != yield(predicate)
      - else
        %div{:about => get_curie(subject), :typeof => typeof}
          - if typeof
            %span.type!= typeof
          %table.properties
            - predicates.each do |predicate|
              != yield(predicate)
    ),

    # Output for single-valued properties
    # Locals: property, objects
    # Yields: object
    # If nil is returned, render as a leaf
    # Otherwise, render result
    :property_value => %q(
      - object = objects.first
      - if heading_predicates.include?(predicate) && object.literal?
        %h1{:property => get_curie(predicate), :content => get_content(object), :lang => get_lang(object), :datatype => get_dt_curie(object)}= escape_entities(get_value(object))
      - else
        %tr.property
          %td.label
            = get_predicate_name(predicate)
          - if res = yield(object)
            != res
          - elsif object.node?
            %td{:resource => get_curie(object), :rel => get_curie(predicate)}= get_curie(object)
          - elsif object.uri?
            %td
              %a{:href => object.to_s, :rel => get_curie(predicate)}= object.to_s
          - elsif object.datatype == RDF.XMLLiteral
            %td{:property => get_curie(predicate), :lang => get_lang(object), :datatype => get_dt_curie(object)}<!= get_value(object)
          - else
            %td{:property => get_curie(predicate), :content => get_content(object), :lang => get_lang(object), :datatype => get_dt_curie(object)}= escape_entities(get_value(object))
    ),

    # Output for multi-valued properties
    # Locals: property, rel, :objects
    # Yields: object for leaf resource rendering
    :property_values =>  %q(
      %tr.property
        %td.label
          = get_predicate_name(predicate)
        %td{:rel => (get_curie(rel) if rel), :property => (get_curie(property) if property)}
          %ul
            - objects.each do |object|
              - if res = yield(object)
                != res
              - elsif object.node?
                %li{:resource => get_curie(object)}= get_curie(object)
              - elsif object.uri?
                %li
                  %a{:href => object.to_s}= object.to_s
              - elsif object.datatype == RDF.XMLLiteral
                %li{:lang => get_lang(object), :datatype => get_curie(object.datatype)}<!= get_value(object)
              - else
                %li{:content => get_content(object), :lang => get_lang(object), :datatype => get_dt_curie(object)}= escape_entities(get_value(object))
    ),
  }
end