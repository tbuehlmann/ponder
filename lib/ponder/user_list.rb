module Ponder
  # The UserList class holds information about users a Thaum is able to see
  # in channels.
  class UserList
    attr_reader :users

    def initialize
      @users = Set.new
      @mutex = Mutex.new
      @thaum_user = nil
    end

    def add(user, thaum_user = false)
      @mutex.synchronize do
        @users << user
        @thaum_user = user if thaum_user
      end
    end

    def remove(user_or_nick)
      @mutex.synchronize do
        user = find(user_or_nick) if user_or_nick.is_a?(String)
        @users.delete(user)
      end
    end

    # Find a User given the nick.
    def find(nick)
      @users.find { |u| u.nick.downcase == nick.downcase }
    end

    def has_user?(user)
      @users.include? user
    end

    def clear
      @mutex.synchronize do
        @users.clear
      end
    end

    # Removes all users from the UserList that don't share channels with the
    # Thaum.
    def kill_zombie_users(users)
      @mutex.synchronize do
        (@users - users - Set.new([@thaum_user])).each do |user|
          @users.delete(user)
        end
      end
    end
  end
end
