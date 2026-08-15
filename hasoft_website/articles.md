---
layout: default
title: Articles
---

# Articles & Guides

Stay up to date with the latest news, tutorials, and technical deep dives into Hasoft packages.

{% if site.posts.size > 0 %}
  <ul>
    {% for post in site.posts %}
      <li>
        <a href="{{ post.url | relative_url }}">{{ post.title }}</a>
        <small>({{ post.date | date: "%b %-d, %Y" }})</small>
        <p>{{ post.excerpt }}</p>
      </li>
    {% endfor %}
  </ul>
{% else %}
  <p>Coming soon! We are preparing high-quality content for you.</p>
{% endif %}
