const Movie = require('../models/movie-model');

createMovie = async (req, res) => {
  const body = req.body;

  if (!body) {
    return res.status(400).json({
      success: false,
      error: 'You must provide a movie',
    });
  }

  const movie = new Movie(body);

  if (!movie) {
    return res.status(400).json({ success: false, error: err });
  }

  try {
    await movie.save();
    return res.status(201).json({
      success: true,
      id: movie._id,
      message: 'Movie created!',
    });
  } catch (err) {
    return res.status(400).json({
      err,
      message: 'Movie not created!',
    });
  }
};

updateMovie = async (req, res) => {
  const body = req.body;

  if (!body) {
    return res.status(400).json({
      success: false,
      error: 'You must provide a body to update',
    });
  }

  try {
    const movie = await Movie.findByIdAndUpdate(req.params.id, body);
    return res.status(200).json({
      success: true,
      id: movie._id,
      message: 'Movie updated!',
    });
  } catch (err) {
    console.log(err);
    return res.status(404).json({
      err,
      message: 'Movie not updated!',
    });
  }
};

deleteMovie = async (req, res) => {
  try {
    const movie = await Movie.findByIdAndDelete(req.params.id);

    if (!movie) {
      return res.status(404).json({ success: false, error: `Movie not found` });
    }
    return res.status(200).json({ success: true, data: movie });
  } catch (err) {
    console.log(err);
    return res.status(400).json({ success: false, error: err });
  }
};

getMovieById = async (req, res) => {
  try {
    const movie = await Movie.findOne({ _id: req.params.id });
    return res.status(200).json({ success: true, data: movie });
  } catch (err) {
    return res.status(400).json({ success: false, error: err });
  }
};

getMovies = async (req, res) => {
  try {
    const movies = await Movie.find({});
    if (!movies.length) {
      return res.status(404).json({ success: false, error: `Movie not found` });
    }
    return res.status(200).json({ success: true, data: movies });
  } catch (err) {
    return res.status(400).json({ success: false, error: err });
  }
};

module.exports = {
  createMovie,
  updateMovie,
  deleteMovie,
  getMovies,
  getMovieById,
};
