/*
This SQL script ranks movie directors by the average rating for all their horror movies. In effect, the metric shows the consensus rating for the sum total of a director's work in the horror genre.
As an alternative metric, the highest average rating for any specific movie is provided. In some circumstances, a director might have created a great film that they are remembered for, but also some bad ones that brings down the average. The metric might be used when a director’s work varies significantly in quality.
Context is given for the averages by showing the number of ratings and number of movies included in the calculation.
The key data dependency is for the relevant movies to be correctly classified within the database as horror.
*/

SELECT
	ROW_NUMBER() OVER( -- Rank each director in order by average rating, followed by number of reviews
		ORDER BY
			avg(r.rev_stars) desc,
			count(r.rev_stars) desc
	) AS 'Rank',
	trim(d.dir_fname) + ' ' + trim(d.dir_lname) AS 'Director', -- Concatenate director's first name and last name
	avg(r.rev_stars) AS 'Average Rating for Horror Movies',
	max(sq.[Average Review for Movie]) AS 'Highest Average Rating for a Movie', -- Subquery for returning average at a movie level
	count(r.rev_stars) AS 'Number of Ratings for Horror Movies',
	count(DISTINCT m.mov_id) AS 'Number of Rated Horror Movies'
FROM
	director d -- The data is aggregated for each director, so join from the director table on primary keys
	LEFT JOIN movie_direction md ON d.dir_id = md.dir_id
	LEFT JOIN movie m ON md.mov_id = m.mov_id
	LEFT JOIN movie_genres mg ON m.mov_id = mg.mov_id
	LEFT JOIN genres g ON mg.gen_id = g.gen_id
	LEFT JOIN rating r ON m.mov_id = r.mov_id
	LEFT JOIN ( -- Subquery as different level of granularity
		select
			mov_id,
			avg(rev_stars) AS 'Average Review for Movie'
		from
			rating
		where
			rev_stars IS NOT NULL
			AND rev_stars <> 0
		group by
			mov_id
	) AS sq ON m.mov_id = sq.mov_id
WHERE
	g.gen_title = 'Horror' -- This is the filter criteria for horror movies, ideally it would be on gen_id when the id is known
	AND r.rev_stars IS NOT NULL -- Do not include instances where there is no join in the calculation of the average
	AND r.rev_stars <> 0 -- Assumption: 0 = data error, so don't include in the calculation of the average
GROUP BY
	d.dir_fname,
	d.dir_lname,
	g.gen_title
ORDER BY
	avg(r.rev_stars) desc,
	count(r.rev_stars) desc