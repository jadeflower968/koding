kd                    = require 'kd'
React                 = require 'kd-react'
immutable             = require 'immutable'
formatEmojiName       = require 'activity/util/formatEmojiName'
DropboxItem           = require 'activity/components/dropboxitem'
emojify               = require 'emojify.js'
renderEmojiSpriteIcon = require 'activity/util/renderEmojiSpriteIcon'


module.exports = class EmojiDropboxItem extends React.Component

  @defaultProps =
    item       : immutable.Map()
    isSelected : no
    index      : 0
    query      : ''


  componentDidMount: ->

    icon = React.findDOMNode @refs.icon
    emojify.run icon, renderEmojiSpriteIcon


  renderEmojiName: ->

    { item, query } = @props

    index = item.indexOf query
    if index is 0
      formatEmojiName item
    else
      <span>
        :{item.substring 0, index}
        <strong>{query}</strong>
        {item.substring index + query.length}:
      </span>


  render: ->

    { item } = @props
    <DropboxItem {...@props} className="EmojiDropboxItem">
      <span className='emojiSpriteIconWrapper'>
        <span ref='icon'>{formatEmojiName item}</span>
      </span>
      {@renderEmojiName()}
    </DropboxItem>

