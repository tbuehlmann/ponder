require 'thread'

module Ponder
  # The UserList class holds information about users a Thaum is able to see
  # in channels.
  class UserList
    def initialize
      @users = {}
      @mutex = Mutex.new
    end

    def users
      @mutex.synchronize do
        @users
      end
    end

    def add(user, thaum_user = false)
      @mutex.synchronize do
        @users[user.nick.downcase] = user
        @thaum_user = user if thaum_user
      end
    end

    def remove(nick)
      @mutex.synchronize do
        remove_user_without_lock(nick)
      end
    end

    def find(nick)
      @mutex.synchronize do
        @users[nick.downcase]
      end
    end

    def clear
      @mutex.synchronize do
        @users.clear
      end
    end

    def kill_zombie_users(users)
      @mutex.synchronize do
        (@users.values - users).each do |user|
          if user != @thaum_user
            remove_user_without_lock(user.nick)
          end
        end
      end
    end

    private

    def remove_user_without_lock(nick)
      @users.delete(nick.downcase)
    end
  end
end
