package PubSubHubBub::Plugin;

use strict;
use warnings;
use MT::Util qw(trim);

sub send_ping {
    my($cb, %param) = @_;

    my $tmpl = $param{template};
    if ($tmpl && $tmpl->identifier eq 'feed_recent') {
        my $blog = $param{blog};
        my $plugin = MT->component('PubSubHubBub');

        unless ($blog) {
            if (MT->config->DebugMode > 0) {
                MT->log({ message => 'No blog context was passed to send_ping.' });
            }
            return;
        }
        my $hubstr = trim($plugin->get_config_value('hubs', "blog:" . $blog->id));
        return unless $hubstr && $hubstr ne '';
        my @hubs = ($hubstr =~ /(\S+)/g);

        my $ua = MT->new_ua({ agent => join("/", $plugin->name, $plugin->version) });
        my $feed_url = $blog->site_url;
        $feed_url .= '/' unless $feed_url =~ m!/$!;
        $feed_url .= $tmpl->outfile;
        for my $hub (@hubs) {
            my $res = $ua->post($hub, { "hub.mode" => "publish", "hub.url" => $feed_url });
            MT->log("Pinged $hub: " . $res->status_line);
        }
    }
}

sub _hdlr_link_tags {
    my($ctx, $args, $cond) = @_;

    my $plugin = MT->component('PubSubHubBub');
    my $blog = $ctx->stash('blog') or return '';

    my $tag = '';
    my @hubs = $plugin->get_config_value('hubs', "blog:" . $blog->id) =~ /(\S+)/g;
    for my $hub (@hubs) {
        $tag .= sprintf qq(<link rel="hub" href="%s" />\n), MT::Util::encode_xml($hub);
    }

    return $tag;
}

1;
