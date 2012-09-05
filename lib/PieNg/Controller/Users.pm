package PieNg::Controller::Users;
use Moose;
use namespace::autoclean;

use Email::Valid;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

PieNg::Controller::Users - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head2 index

=cut

sub index :Path :Args(0) {
    my ($self, $c) = @_;
    $c->detach('/users/list');
}

=head2 add

Add a new user.  If the request method is not a POST, then a form
to add user data to will be presented.  If submitted (and the
user doing the submission is an admin) then the user will be
added to the database.

=cut

sub add :Local :Args(0) {
    my ($self, $c) = @_;
    $c->stash->{'template'} = 'users/add.tt';

    # if we are actually submitting a form
    if(lc $c->req->method eq 'post' ) {
        # if we are doing so as an administrator
        if($c->check_user_roles( qw/ administrator / )) {
            my $params = $c->req->params;

            if(!Email::Valid->address($params->{email})) {
                $c->stash->{'message'} = $params->{email} . " is not a valid email address.";
                return;
            }

            # if our passwords match up
            if($params->{password1} eq $params->{password2} &&
               length $params->{password1} > 2) {

                my $new_user = eval { $c->model('PieDB::User')->create({
                    username => $params->{username},
                    email    => $params->{email},
                    password => $params->{password1} }) };

                my $role = $c->model('PieDB::Role')->find(
                                     { name => $params->{role} } );
                $new_user->user_roles->create({ role => $role->id });

                # If we get to this point the user should have been created.
                $c->flash->{'message'} = "Created user " . $params->{username};
                # Let's head over to our user list to make sure...
                $c->response->redirect($c->uri_for(
                        $c->controller('Users')->action_for('list')));
                $c->detach();
            }
            else {
                $c->stash->{'message'} = "Passwords don't match." 
            }
                
        }
        else {
            $c->stash->{'message'} = "You are not an administrator."
        }
    }
}

=head2 delete

=cut

sub delete :Local :Args(1) {
    my ($self, $c, $id) = @_;
    $c->stash->{'template'} = 'users/delete.tt';

    my $deluser = $c->model('PieDB::User')->find(
                                     { id => $id } );
    if(!defined $deluser) {
        $c->stash->{'message'} = "No such user id.";
        return;
    }

    if(!$c->check_user_roles( qw/ administrator / )) {
        $c->stash->{'message'} = "You are not an administrator.";
    }
    elsif(lc $c->req->method eq 'post') {
        $deluser->user_roles->delete();
        $deluser->delete();
        $c->response->redirect($c->uri_for(
                $c->controller('Users')->action_for('list')));
        $c->detach();
    }

    $c->stash->{'deluser'} = $deluser;
}

=head2 edit

=cut

sub edit :Local :Args(1) {
    my ($self, $c, $id ) = @_;
    $c->stash->{'template'} = 'users/edit.tt';

    # Use the argument passed in (which should be the
    # id of a user record).  The argument could also be
    # supplied by $c->req->args->[0] .
    my $edituser = $c->model('PieDB::User')->find(
                                     { id => $id } );
    if(!defined $edituser) {
        $c->stash->{'message'} = "No such user id.";
        return;
    }

    # If the edit form has actually been submitted...
    if(lc $c->req->method eq 'post') {
        # if we are doing so as an administrator
        if($c->check_user_roles( qw/ administrator / )) {
            my $params = $c->req->params;

            if(!Email::Valid->address($params->{email})) {
                $c->stash->{'message'} = $params->{email} . " is not a valid email address.";
                return;
            }

            # if our passwords match up
            if($params->{password1} eq $params->{password2} &&
               length $params->{password1} > 2) {

                eval { $edituser->update({
                    email    => $params->{email},
                    password => $params->{password1},
                    status   => $params->{status} }) };

                my $role = $c->model('PieDB::Role')->find(
                                     { name => $params->{role} } );
                $edituser->user_roles->delete();
                $edituser->user_roles->create({ role => $role->id });

                # If we get to this point the user should have been updated.
                $c->flash->{'message'} = "Updated user " . $params->{username};
                # Let's head over to our user list to make sure...
                $c->response->redirect($c->uri_for(
                        $c->controller('Users')->action_for('list')));
                $c->detach();
            }
            else {
                $c->stash->{'message'} = "Password mismatch or too short."
            }

        }
        else {
            $c->stash->{'message'} = "You are not an administrator."
        }

    }
    else {
        # If we are just going to display the user edit form, we
        # will give it the user to edit.
        $c->stash->{'edituser'} = $edituser;
    }
}

=head2 list

List the user records.

=cut

sub list :Local :Args(0) {
    my ($self, $c) = @_;
    $c->stash->{'template'} = 'users/list.tt';

    my $list_rs = $c->model('PieDB::User')->search(
                            undef,
                            { order_by => 'username' } );
    @{$c->stash->{'users'}} = $list_rs->all();
    $c->stash->{'status_info'} = $PieNg::STATUS_INFO;
    $c->stash->{'message'} = $c->flash->{'message'};
}

=head2 login

=cut

sub login :Local :Args(0) {
    my ($self, $c) = @_;
    $c->stash->{'template'} = 'users/login.tt';

    # We will want to remember the requested URI so that once login
    # works we can get directed to it.
    my $requested;
    if( defined $c->req->params->{'requested'} ) {
        $requested = $c->req->params->{'requested'};
    }
    else {
        $requested = $c->req->uri;
    }

    $c->stash->{'requested'} = $requested;

    if( exists($c->req->params->{'username'}) ) {
        $c->stash->{'message'} = 'What?';
        if( $c->authenticate({ username => $c->req->params->{'username'},
                               password => $c->req->params->{'password'},
                               status => [ 1 ] }) ) {

            $c->res->redirect($requested);
            $c->detach();
        }
        else {
            $c->stash->{'message'} = 'Authentication Failed';
        }
    }

}

=head2 logout

=cut

sub logout :Local :Args(0) {
    my ($self, $c) = @_;
    $c->stash->{'template'} = 'users/logout.tt';

    $c->logout();
}

=head1 AUTHOR

TimH

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
