if has('python') 
    python << EOF
# -*- coding: utf-8 -*-

# ########################
# Wordpress posting script 
# ------------------------
# Author:   Marijn Koesen
# Version:  v1.5.4
# Date:     5 Aug 2008
#
# Original script: 
# http://not.upbylunch.com/2006/05/16/wordpress-posting-vim-script/
# 
# Modified version by Marijn Koesen:
# https://bitbucket.org/MarijnKoesen/wordpress-vim-plugin/overview
#
# ########################
# Description
#
# This script lets you administer posts in Wordpress with Vim. 
# By using the xmlrpc functionality of wordpress this script can edit posts and post new posts. 
# The script even allows you to set the post categories, (optional) tags and the post status 
# to either public or private.
#
# Besides the posting, the script allows you to fetch a list of all posts on the server, and a  
# hierarchial list of the available categories. But for these features Wordpress must be hacked 
# a little bit. These hacks can be found in de Installation section. 
#
# ########################
# Installation:
#
# 1.    Make sure vim is compiled with Python support
# 2.    Add this script to your ~/.vim/plugin/ directory on linux or 
#       vimfiles/plugin directory on windows.
# 3.    Set the username and url of your blog in this script
# 4.    Optionally set the password, but this is insecure 
# 5.    Create a webpage in which you show all the avaialable topics
#       and set the url accordingly in the source of this file
# 6.    Optionally, edit wordpress' xmlrpc.php so that posts with 'publish' set to false
#       will be saved as private posts, instead of drafts. This way they'll show up on 
#       the blog as normal posts, when you're logged in with the sufficient priveleges
#       To do this, edit the mw_editPost/mw_newPost functions in xmlrpc.php: 
#       replace
#           "$post_status = $publish ? 'publish' : 'draft';"
#       with
#            "$post_status = $publish ? 'publish' : 'private';" 
# 7.    Optinally, to get a hierarchial category listing, edit the mw_getCategories 
#       function and edit the query to include 'category_parent' column from the database:
#           ex: "SELECT cat_ID,cat_name, category_parent FROM $wpdb->categories"
#       now add the category_parent db-column to the returning data array: 
#           $struct['parent'] = $cat['category_parent'];
# 8.    For using categorie names in the Add the following in the foreach categories loop 
#       in the mt_setPostCategories function:
#            if (!is_numeric($cat['categoryId'])) $cat['categoryId'] = get_cat_ID($cat['categoryId']);
#
# ########################
# Usage:
#
# Get post from server:
# :py get_blog(34)
# :py b_g(34)
#
# Save post to server:
# :py post_blog()
# :py b_p()
#
# Open a new posttemplate:
# :py blog_template()
# :py b_t()
#
# Category list:
# :py blog_cat_list()
#
# Topic list:
# :py blog_post_list() or 
# :py blog_list()
#
# ########################
# Changelog:
#
# v0.5.5 (21-10-2008)
#  * Use wordpress' post_status flag while retreiving a post, previously we had to
#    modify wordpress for this flag, now it's being sent in standard wordpress
#  * Use the getRecentPosts interface to get a list of the posts, this makes our
#    own topic list script unnecessary, which means minimal wordpress mods :)
#  * Changed the names of the topic list buffers to '-post-list.blog' 
#  * Change temporary post locations to /non-existent/$tempfile$ this makes sure
#    the posts cannot be saved when using the ':w' command without a password. This
#    is done so that you don't accidentally save it to disk instead of to wordpress.
#  * Add the b_g(), b_p() and b_t() aliasses for get, post and template
#
# v0.5.4 (17-01-2007)
#  * Added the ability to post using category names instead of id's
#
# v0.5.3 (17-01-2007)
#  * Changed the names of the category list buffers to '-cat-list.blog' 
#  * Changed the names of the topic list buffers to '-list.blog' 
#  * Added some Todo items
#
# v0.5.2 (28-01-2007)
#  * Set nomodified when blog_list() is fetched from the server
#  * Set nomodified when blog_cat_list() is fetched from the server
#  
#
# v0.5.1 (20-01-2007)
#  * Set nomodified when post is fetched from the server
#  * Updated the 'Usage' section to be more desctiptive
#  * Updated the 'Description' section with new features
#  * Updated the 'Installation' section with better english
#  * Added some Todo items
#
# v0.5 (06-01-2007)
#  * Added support for category editing and updated the templates
#  * Added a new function 'blog_cat_list()' that shows a hierarchical tree
#    of the available categories.
#  * Fixed a bug where a <!--more--> tag would always be inserted in a post
#  * Fixed Wordpress 2.1 support
#  * More little tweaks, quality improvements
#  * Updated the installation steps to include xmlrpc modifications
#  * Added unicode support, this was a nasty bug, see:
#    http://tech.groups.yahoo.com/group/vim-multibyte/message/2253
#  * Removed some old code
#
# v0.4 (01-01-2007)
#  * Reintroduced the use of tags in the post see (blog_template())
#  * Fixed some typo's
#  * Removed some old code
# 
# v0.3 (29-12-2006)
#  * Added a new function blog_template()
#  * Added a 'post saved' message, when all went well
#  * Added the functionality to save a post as draft/private. 
#  * When posting, check if the content is like the template
#  * Fixed a bug where posting would not work before calling get_blog()
#  * Fixed a bug where posting a title containing a ":" would only be 
#    posted upto the ":" but nothing after the ":"
#  * The script now uses random-temporary files to edit the posts.
#    This way multiple posts can be edited and added simultaniously.
#
# v0.2 (6-12-2006)
#  * Added a check if python is installed, if not inform the user
#  * Use vim's inputsecret() instead of input() to hide the pass 
# 
# v0.1 (5-12-2006)
#  * Replaced the hardcoded password by a password-question to the user
#  * Disabled the tag support
#  * Show the categories on the post in ViM
#  * get_blog(id) implemented
#  * Improved error checking
#
# ########################
# Todo:
#  * Write a configuration section in which the configuration if exmplained
#     * blog_url, including password protection urls (http://user:pass@hhost)
#  * Fix bug where pressing CTRL+C while entering a password makes the script
#    defective so that logging in is not possible anymore, reloading the script
#    (source ~/.vim/plugins/wordpress.vim) works until a fix is created
#  * Make tags optional
#  * Refactor
#     - Proxy function for buffer.append() which handles the UTF-8 encoding
#     - Lots of cleanups and dead code removal
#  * Make script work with unmodified versions of wordpress
#  * Make script workable with: 
#       blog_url = 'https://www.yourblog.com/xmlrpc.php' set
#    now it produces errors 

import urllib
import urllib2
import vim
import xml.dom.minidom
import xmlrpclib
import os
import os, tempfile
import time
import string

blog_username = 'admin'
blog_password = ''
blog_url = 'https://www.yourblog.com/xmlrpc.php'
num_posts = 9999 # How many posts to show in blog_list_posts()

def make_tags(text, numtags=5):
    params = urllib.urlencode({
        'appid': 'upbylunch',
        'context': text
    })

    u = urllib2.urlopen("http://api.search.yahoo.com/ContentAnalysisService/V1/termExtraction", params)
    response = u.read()
    
    doc = xml.dom.minidom.parseString(response)
    tags = [str(i.childNodes[0].nodeValue) for i in doc.getElementsByTagName('Result')]

    return tags[:numtags]

def build_cat_tree(parent, items):
    for item in items:
        if str(item['parentId']) == str(parent['categoryId']):
            item['children'] = []
            item = build_cat_tree(item, items)
            parent['children'].append(item)

    return parent

def print_cat_tree(item, indentLvl=0):
    indent = '    ' * indentLvl;
    string = '%(id)02s %(indent)s %(name)s' % { 'id' : int(item['categoryId']), 'indent' : indent, 'name' : item['categoryName'] }
    vim.current.buffer.append(string.encode('utf-8'))

    # TODO: fixme
    try:
        if len(item['children']) > 0:
            for child in item['children']:
                print_cat_tree(child, indentLvl+1)
    except:
        some = 'foo'


def blog_cat_list():
    if load_password() == -1:
        # Server error
        return

    # Get the content
    try: 
        wp = xmlrpclib.ServerProxy(blog_url)
        categories = wp.metaWeblog.getCategories(1, blog_username, blog_password)
    except xmlrpclib.ProtocolError,xmlrpclib.ResponseError:
        print_server_error(xmlrpclib.ResponseError)
        return
    except xmlrpclib.Fault,xmlrpclib.ResponseError:
        print "Topic '" + str(id) + "' bestaat niet."
        return

    root = { 'categoryId' : 0, 'categoryName' : 'root', 'children' : [] }
    cat_tree = build_cat_tree(root, categories)

    tmpFile = tempfile.mktemp('-cat-list.blog')
    vim.command("edit /non-existent/" + tmpFile)

    vim.current.buffer[-1] = "Category list: "
    vim.current.buffer.append("")
    print_cat_tree(cat_tree)

    vim.command('set nomodified')

def b_t():
    blog_template()

def blog_template():
    tmpFile = tempfile.mktemp('.blog')
    vim.command("edit /non-existent/" + tmpFile)
    template = "Title: \n"
    template += "Categories: (comma seperated list)\n" 
    template += "Publish: 0\n"
    template += "Tags: (comma seperated list)\n"
    template += "Some content"
    print_text(template, "", "", 1)

def get_blog_template(noPostId=0):
    template = ""

    if noPostId == 0:
        template += "PostID: [0-9]+\n"

    template += "Title: (.*)\n"
    template += "Categories: 1, (comma seperated list)\n" 
    template += "Publish: (0|1)\n"
    template += "Tags: (comma seperated list)\n"
    #template += "Categories: ([0-9]+\w*)+\n"
    template += "# The comment block after 'Categories' will be filtered\n"
    template += "# from the post content. The other comment blocks are\n"
    template += "# left intact. \n"
    template += "[optional whitespace line]\n"
    template += "Some content"
    return template;

def is_numeric(c):
    return (c >= '0' and c <='9')

def b_p(numtags=5):
    post_blog(numtags)

def post_blog(numtags=5):
    if load_password() == -1:
        # Server error
        return

    strid = ''
    line = 0

    # look for the [PostID, Title, Publish, Tags, Comment] tags in these order, if tag is not found, return

    # Parse postID 
    if vim.current.buffer[line].find('PostID:') != -1:
        strid = vim.current.buffer[line][7:].strip()
        line += 1

    # Parse title
    if vim.current.buffer[line].find('Title:') != -1:
        title = vim.current.buffer[line][6:].strip()
        line += 1
    else:   
        print "Error. Post template is not correct. Must be:"
        print get_blog_template()
        return

    # Parse categories
    categoriesOk = 0
    # TODO: check if we only got id's
    if vim.current.buffer[line].find('Categories:') != -1:
        categories_temp = vim.current.buffer[line][11:].strip()
        categories_temp = categories_temp.split(',')
        categories = []        

        for cat in categories_temp:
            if len(cat.strip()) > 0:
                # Check if the category is numeric
                # TODO: find a proper python way to do this
                try:
                    categories.append({ 'categoryId' : cat.strip() })
                except:
                    print "Category '" + cat.strip() + "' is not numeric."
                    return
            
        if len(categories) > 0:        
            categoriesOk = 1
            line += 1 
 
    if categoriesOk == 0: 
        print "Error. Post template is not correct. Must be:"
        print get_blog_template()
        return

    # Parse publish
    publishOk = 0
    if vim.current.buffer[line].find('Publish:') != -1:
        publish = (vim.current.buffer[line].split(':')[1]).strip()

        # If we find "Publish: 0|1" set ipublish with the bool
        if publish.isdigit() and (int(publish) == 0 or int(publish) == 1):
            ipublish = int(publish)
            publishOk = 1
            line += 1

    if publishOk == 0:
        print "Error. Post template is not correct. Must be:"
        print get_blog_template()
        return

    # Parse tags 
    if vim.current.buffer[line].find('Tags:') != -1:
        tags = vim.current.buffer[line][5:].strip()
        line += 1
    else:   
        print "Error. Post template is not correct. Must be:"
        print get_blog_template()
        return
    

    # Parse (skip) the comments
    if len(vim.current.buffer) > line:
        foundComment = 1
        while foundComment == 1:
            if len(vim.current.buffer[line]) == 0: 
                foundComment = 0
            elif vim.current.buffer[line][0] != "#":
                foundComment = 0
            else:
                line += 1

    
    # Join the remaining lines with a new line
    if len(vim.current.buffer) > line:
        text = "\n".join(vim.current.buffer[line:])
        text = text.strip()
    else: 
        text = ""

    # Tag condition
    if tags == "":      
        # Get the content from yahoo or something:
        # http://coopblue.com/blog/2006/06/posting-to-wordpress-from-vim-with-tags-and-markdown/
        #tags = "[tags\]" + ",".join(make_tags(text, numtags)) + "[/tags]\n"
        tags = ""
        text = tags + text
    else:
        text = "[tags]" + tags + "[/tags]\n" + text

    # Post the post to the server
    wp = xmlrpclib.ServerProxy(blog_url)
    post = {
        'title': title,
        'description': text
    }

    try:
        if strid == '':
            strid = wp.metaWeblog.newPost('', blog_username, blog_password, post, ipublish)

            # Add 'PostID: [id]' to the top of the post
            vim.current.buffer[:] = ['PostID:' + strid] + [i for i in vim.current.buffer[:]]
        else:
            wp.metaWeblog.editPost(strid, blog_username, blog_password, post, ipublish)

        wp.mt.setPostCategories(strid, blog_username, blog_password, categories)

        # If all goed well
        vim.command('set nomodified')
        print "Post saved"

    except xmlrpclib.Fault,xmlrpclib.ResponseError: 
        print "Error while saving:"
        print xmlrpclib.ResponseError

    except:
        print "Error while saving."  


def clear_buffer(buf):
    buf[:] = None



def load_password():
    global blog_password
    
    # check the password
    try: 
        wp = xmlrpclib.ServerProxy(blog_url)
        wp.metaWeblog.getPost(13333, blog_username, blog_password)
        return 0
    except xmlrpclib.ProtocolError,xmlrpclib.ResponseError:
        print_server_error(xmlrpclib.ResponseError)
        return -1
    except xmlrpclib.Fault,xmlrpclib.ResponseError:       
        # print "Error while check the password. Possible reasons are:"
        # print " - your weblog doesn't support the MetaWeblog API"
        # print " - your weblog doesn't like the username/password combination you've provided."

        if str(xmlrpclib.ResponseError) == "<Fault 403: 'Bad login/pass combination.'>":
            blog_password = vim.eval('inputsecret("Password:")');
            load_password()

    # If all goed well
    return 0 

def print_server_error(error):
    print "Error while conection to the server. Possible reasons are:"
    print " - The weblog doesn't exist"
    print " - Path to xmlrpc server is incorrect"
    print "Check for typos."
    print
    print 'Error: '+ str(error)

# TODO: booleanenize withNames
def category_list_to_string(categoryList,withNames=0):
    categoryString = ''

    length = 0
    for cat in categoryList:
        if withNames == 0:
            categoryString += str(cat['categoryId']) + ", "
        else:
            categoryString += "[" + str(cat['categoryId']) + ":" + cat['categoryName'] + "], "

    if len(categoryString) > 0: 
        # strip last ", "
        categoryString = categoryString[:-2]

        return categoryString.encode('utf-8')
    else: 
        return ""

# Takes a string that is delimited by "\n"
# The text is exploded on "\n" and multiple
# lines are printed
def print_text(text, lineprefix="", linepostfix="", startAtLine0 = 0):
    lines = text.split("\n")
    i = 0 
    for line in lines:
        # TODO: check this code, it's quite messy, what's the i, what does the else do?
        if i == 0:
            if startAtLine0 == 1:
                vim.current.buffer[-1] = lineprefix + line + linepostfix
            else:
                vim.current.buffer.append(lineprefix + line + linepostfix)
        else: 
            string = line + linepostfix
            string2 = string.rjust(len(lineprefix) + len(string))
            vim.current.buffer.append(string2.encode('utf-8'))

        i = i +1

def sort_posts_by_title(a, b):
    # Do a case insenitive compare
    return cmp(a['title'].lower(), b['title'].lower())

def blog_list():
    blog_post_list()

def blog_post_list():
    if load_password() == -1:
        # Server error
        return

    # Set the vim status bar
    print "Fetching list of posts... this may take a while..."

    # Get the posts 
    try: 
        wp = xmlrpclib.ServerProxy(blog_url)
        #posts = wp.mt.getRecentPostTitles(1, blog_username, blog_password, num_posts)
        posts = wp.metaWeblog.getRecentPosts(1, blog_username, blog_password, num_posts)
    except xmlrpclib.ProtocolError,xmlrpclib.ResponseError:
        print_server_error(xmlrpclib.ResponseError)
        return
    except xmlrpclib.Fault,xmlrpclib.ResponseError:
        print "Topic '" + str(id) + "' bestaat niet."
        return

    # Now write the content
    tmpFile = tempfile.mktemp('-post-list.blog')
    vim.command("edit /non-existent/" + tmpFile)

    # Output ordered by ID
    vim.current.buffer[-1] = '# List of the latest ' + str(num_posts) + ' posts'
    vim.current.buffer.append("")
    vim.current.buffer.append("#")
    vim.current.buffer.append('## Posts ordered by PostID')
    vim.current.buffer.append("#")

    for post in posts:
        # Available keys: mt_keywords, permaLink, wp_slug, description, title, post_status, 
        # date_created_gmt, mt_excerpt, userid, dateCreated, custom_fields, wp_author_display_name, 
        # link, mt_text_more, mt_allow_comments, wp_password, postid, wp_author_id, categories, 
        # mt_allow_pings,
        formattedPostId = post['postid'].rjust(4, ' ')
        vim.current.buffer.append(formattedPostId + ' ' + post['title'].encode('utf-8'))

    # Output ordered by Topic Title
    vim.current.buffer.append("")
    vim.current.buffer.append("#")
    vim.current.buffer.append('## Posts ordered by Topic Title')
    vim.current.buffer.append("#")

    posts.sort(sort_posts_by_title)

    for post in posts:
        # Available keys: mt_keywords, permaLink, wp_slug, description, title, post_status, 
        # date_created_gmt, mt_excerpt, userid, dateCreated, custom_fields, wp_author_display_name, 
        # link, mt_text_more, mt_allow_comments, wp_password, postid, wp_author_id, categories, 
        # mt_allow_pings,
        formattedPostId = post['postid'].rjust(4, ' ')
        vim.current.buffer.append(formattedPostId + ' ' + post['title'].encode('utf-8'))
    

    vim.command('set nomodified')

def b_g(id):
    get_blog(id)

def get_blog(id):
    if load_password() == -1:
        # Server error
        return

    # Get the content
    try: 
        wp = xmlrpclib.ServerProxy(blog_url)
        content = wp.metaWeblog.getPost(id, blog_username, blog_password)
        categories = wp.mt.getPostCategories(id, blog_username, blog_password)
    
        if len(content['mt_text_more']) > 0:    
            post = content['description'] + "\n\n<!--more-->\n" + content['mt_text_more']   
        else:
            post = content['description']

        post = post.encode('utf-8')
        lines = post.split("\n")
    except xmlrpclib.ProtocolError,xmlrpclib.ResponseError:
        print_server_error(xmlrpclib.ResponseError)
        return
    except xmlrpclib.Fault,xmlrpclib.ResponseError:
        print "Topic '" + str(id) + "' bestaat niet."
        return

    tmpFile = tempfile.mktemp('.blog')
    vim.command("edit /non-existent/" + tmpFile)

    if content['post_status'] == 'publish':
        publish = "1"
    else: 
        publish = "0"

    if len(lines[0]) > 14 and lines[0][0:6] == '[tags]' and lines[0][-7:] == '[/tags]':
        tags = str(lines[0][6:-7])
        lines.pop(0)
    else:
        tags = ""


    # Now write the content
    vim.current.buffer[-1] = 'PostID: ' + str(id)
    vim.current.buffer.append('Title: ' + content['title'].encode('utf-8'))
    vim.current.buffer.append('Categories: ' + category_list_to_string(categories))
    vim.current.buffer.append('Publish: ' + publish)
    vim.current.buffer.append('Tags: ' + tags)
    vim.current.buffer.append('#Post categories: ' + category_list_to_string(categories,1))

    try:
        vim.current.buffer.append("")
        for line in lines:
            vim.current.buffer.append(line)

    except xmlrpclib.Fault, fault:
        print fault.faultCode
        print fault.faultString

    vim.command('set nomodified')

EOF
else
    echo "ERROR: Wordpress plugin cannot be loaded, check if python is compiled."
endif
