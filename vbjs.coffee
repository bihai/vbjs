parser = require "./vb.js"
escodegen = require "escodegen"

exports.evaluate = (expr, Me) ->
    (compile parse expr)(Me)

repr = (arg) -> require('util').format '%j', arg
pprint = (arg) -> console.log require('util').inspect arg, false, null

parse = (expr) ->
    tree = parser.parse expr

    # copy-pasted from sqld3/parse_sql.coffee
    Object.getPrototypeOf(tree).toString = (spaces) ->
        if not spaces then spaces = ""

        value = (if this.value? then "=> #{repr this.value}" else '')
        string = spaces + this.name +  " <" + this.innerText() + "> " + value
        children = this.children
        index = 0

        for child in children
            if typeof child == "string"
                #string += "\n" + spaces + ' ' + child
            else
                string += "\n" + child.toString(spaces + ' ')

        return string

    tree.traverse
        traversesTextNodes: false
        exitedNode: (n) ->
            n.value = switch n.name
                when 'source', '#document' # language.js nodes
                    n.children[0].value
                when 'start', 'expression', 'value', 'identifier'
                    n.children[0].value
                when 'literal'
                    type: 'Literal'
                    value: n.children[1].value
                when 'literal_text'
                    n.innerText()
                when 'identifier_name'
                    type: 'MemberExpression'
                    computed: yes
                    object:
                        type: 'Identifier'
                        name: 'Me'
                    property:
                        type: 'Literal'
                        value: n.children[1].value
                when 'name'
                    n.innerText()
                when 'add_expression' 
                    op = n.children[1].name

                    if op is 'concat_op'
                        # force conversion to string
                        result = plus {type: 'Literal', value: ''}, \
                                      n.children[0].value
                        for c in n.children[1..] when c.name is 'value'
                            result = plus result, c.value
                        result
                    else if op is 'plus_op'
                        plus a, b

            #if n.name is 'start' then console.log n.toString()

    tree.value

plus = (left, right) ->
    type: 'BinaryExpression'
    operator: '+'
    left: left
    right: right

# compile to JavaScript
compile = (tree) ->
    #pprint tree
    code = escodegen.generate tree
    #console.log 'CODE', code
    new Function 'Me', "return #{code};"

# Usage: coffee vbjs.coffee "[foo]&[bar]"
#parse process.argv[2]
