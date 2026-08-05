class AddSlugToCommunityThreadsAndPosts < ActiveRecord::Migration[8.1]
  def up
    add_column :community_threads, :slug, :string
    add_column :posts, :slug, :string

    CommunityThread.find_each do |thread|
      thread.update_column(:slug, unique_thread_slug(thread.community_id, thread.title.to_s.parameterize.presence || "thread"))
    end

    Post.find_each do |post|
      post.update_column(:slug, SecureRandom.hex(6))
    end

    change_column_null :community_threads, :slug, false
    change_column_null :posts, :slug, false

    add_index :community_threads, [ :community_id, :slug ], unique: true
    add_index :posts, [ :community_thread_id, :slug ], unique: true
  end

  def down
    remove_index :posts, [ :community_thread_id, :slug ]
    remove_index :community_threads, [ :community_id, :slug ]
    remove_column :posts, :slug
    remove_column :community_threads, :slug
  end

  private

  def unique_thread_slug(community_id, base)
    candidate = base
    i = 1
    while CommunityThread.where(community_id: community_id, slug: candidate).exists?
      i += 1
      candidate = "#{base}-#{i}"
    end
    candidate
  end
end
