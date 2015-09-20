clearing :on
notification :tmux,
             display_message: true,
             color_location: ['status-left-bg',
                              'pane-active-border-fg',
                              'pane-border-fg']

guard :shell do
  watch(/(.*).exs/) { |m| `elixir #{m[0]}` }
end
