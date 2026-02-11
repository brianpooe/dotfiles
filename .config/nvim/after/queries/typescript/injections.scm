; extends

; Angular inline template - inject Angular template highlighting into @Component template property
((decorator
  (call_expression
    function: (identifier) @_name
    arguments: (arguments
      (object
        (pair
          key: (property_identifier) @_key
          value: (template_string) @injection.content)))))
  (#eq? @_name "Component")
  (#eq? @_key "template")
  (#set! injection.language "angular")
  (#set! injection.include-children))

; Angular inline styles - inject CSS highlighting into @Component styles property
((decorator
  (call_expression
    function: (identifier) @_name
    arguments: (arguments
      (object
        (pair
          key: (property_identifier) @_key
          value: (array
            (template_string) @injection.content))))))
  (#eq? @_name "Component")
  (#eq? @_key "styles")
  (#set! injection.language "css")
  (#set! injection.include-children))
